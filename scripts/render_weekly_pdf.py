#!/usr/bin/env python3
"""Render a portable weekly training sheet from a Markdown plan."""

from __future__ import annotations

import argparse
import re
import sys
from datetime import date, timedelta
from pathlib import Path

REPORTLAB_ERROR: ModuleNotFoundError | None = None
try:
    from reportlab.lib import colors
    from reportlab.lib.enums import TA_CENTER, TA_LEFT
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
    from reportlab.lib.units import mm
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
except ModuleNotFoundError as exc:
    REPORTLAB_ERROR = exc


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plan", required=True, type=Path, help="Markdown plan file")
    parser.add_argument("--week-start", type=str, help="Monday of the requested week, YYYY-MM-DD")
    parser.add_argument("--output", required=True, type=Path, help="Output PDF path")
    parser.add_argument("--week-label", default="本周", help="Label shown in the PDF header")
    return parser.parse_args()


def parse_week_start(value: str | None) -> date | None:
    if not value:
        return None
    try:
        parsed = date.fromisoformat(value)
    except ValueError as exc:
        raise SystemExit(f"--week-start must be YYYY-MM-DD: {value}") from exc
    return parsed - timedelta(days=parsed.weekday())


def read_frontmatter_and_body(text: str) -> tuple[dict[str, str], str]:
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---", 4)
    if end < 0:
        return {}, text
    metadata: dict[str, str] = {}
    for line in text[4:end].splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        metadata[key.strip()] = value.strip().strip('"\'')
    return metadata, text[end + 4 :]


def clean_cell(value: str) -> str:
    value = re.sub(r"\[([^]]+)\]\([^)]*\)", r"\1", value)
    value = value.replace("<br>", "\n").replace("<br/>", "\n")
    return re.sub(r"\s+", " ", value.strip())


def split_row(line: str) -> list[str]:
    return [clean_cell(cell) for cell in line.strip().strip("|").split("|")]


def is_separator(cells: list[str]) -> bool:
    return bool(cells) and all(re.fullmatch(r"\s*:?-{3,}:?\s*", cell) for cell in cells)


def date_in_week(heading: str, week_start: date | None) -> bool:
    if week_start is None:
        return True
    found = re.search(r"\b(20\d{2})[-年](\d{1,2})[-月](\d{1,2})", heading)
    if not found:
        return True
    heading_date = date(int(found.group(1)), int(found.group(2)), int(found.group(3)))
    return week_start <= heading_date < week_start + timedelta(days=7)


def extract_rows(body: str, week_start: date | None) -> list[list[str]]:
    lines = body.splitlines()
    rows: list[list[str]] = []
    current_day = ""
    index = 0
    while index < len(lines):
        heading = re.match(r"^#{3,4}\s+(.+?)\s*$", lines[index])
        if heading:
            current_day = clean_cell(heading.group(1))
        if lines[index].lstrip().startswith("|") and index + 1 < len(lines):
            headers = split_row(lines[index])
            separator = split_row(lines[index + 1]) if lines[index + 1].lstrip().startswith("|") else []
            if headers and is_separator(separator) and any("动作" in cell or "exercise" in cell.lower() for cell in headers):
                index += 2
                while index < len(lines) and lines[index].lstrip().startswith("|"):
                    cells = split_row(lines[index])
                    mapping = {header: cells[pos] if pos < len(cells) else "" for pos, header in enumerate(headers)}
                    exercise = next((mapping[key] for key in headers if "动作" in key or "exercise" in key.lower()), "")
                    if exercise:
                        def get(*terms: str) -> str:
                            return next((mapping[key] for key in headers if any(term in key.lower() for term in terms)), "")
                        rows.append([
                            current_day,
                            get("顺序", "order"),
                            exercise,
                            get("组", "dose", "次数", "时长"),
                            get("rpe", "rir"),
                            get("休息", "rest"),
                            get("替代", "substitut"),
                            get("完成状态", "status", "状态") or "planned",
                            get("实际", "actual", "备注", "note"),
                        ])
                    index += 1
                continue
        index += 1
    dated_rows = [row for row in rows if date_in_week(row[0], week_start)] if week_start else rows
    return dated_rows if dated_rows else rows


def register_cjk_font() -> str:
    candidates = [
        ("FitnessCJK", "/System/Library/Fonts/PingFang.ttc"),
        ("FitnessCJK", "/System/Library/Fonts/STHeiti Light.ttc"),
        ("FitnessCJK", "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"),
        ("FitnessCJK", "/usr/share/fonts/google-noto-cjk/NotoSansCJK-Regular.ttc"),
    ]
    for name, path in candidates:
        if not Path(path).exists():
            continue
        try:
            pdfmetrics.registerFont(TTFont(name, path))
            return name
        except Exception:
            continue
    raise SystemExit("PDF export needs an installed CJK font such as PingFang or Noto Sans CJK; use Markdown-only output if none is available.")


def paragraph(value: str, style: ParagraphStyle) -> Paragraph:
    safe = value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\n", "<br/>")
    return Paragraph(safe or " ", style)


def build_pdf(plan_path: Path, output_path: Path, week_start: date | None, week_label: str) -> int:
    if REPORTLAB_ERROR is not None:
        raise SystemExit(
            "PDF export requires the optional 'reportlab' package. "
            "Use the skill's dependency preflight to install it in a user or temporary environment, "
            "or choose Markdown-only output."
        ) from REPORTLAB_ERROR
    if not plan_path.exists():
        raise SystemExit(f"Plan file not found: {plan_path}")
    metadata, body = read_frontmatter_and_body(plan_path.read_text(encoding="utf-8"))
    rows = extract_rows(body, week_start)
    if not rows:
        raise SystemExit("No weekly exercise table was found in the selected Markdown plan.")

    font_name = register_cjk_font()
    page_width, page_height = landscape(A4)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    document = SimpleDocTemplate(
        str(output_path), pagesize=(page_width, page_height),
        leftMargin=8 * mm, rightMargin=8 * mm, topMargin=7 * mm, bottomMargin=7 * mm,
        title=f"{week_label}训练计划", author="fitness-coach",
    )
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("Title", parent=styles["Title"], fontName=font_name, fontSize=15, leading=18, alignment=TA_CENTER, textColor=colors.HexColor("#17324D"), spaceAfter=3 * mm)
    meta_style = ParagraphStyle("Meta", parent=styles["Normal"], fontName=font_name, fontSize=7.5, leading=9, alignment=TA_LEFT, textColor=colors.HexColor("#334155"))
    cell_style = ParagraphStyle("Cell", parent=styles["Normal"], fontName=font_name, fontSize=6.5, leading=7.5, alignment=TA_LEFT)
    header_style = ParagraphStyle("Header", parent=cell_style, fontSize=6.3, leading=7.2, alignment=TA_CENTER, textColor=colors.white)
    small_style = ParagraphStyle("Small", parent=styles["Normal"], fontName=font_name, fontSize=6.5, leading=8, textColor=colors.HexColor("#475569"))

    week_text = f"{week_start.isoformat()} 至 {(week_start + timedelta(days=6)).isoformat()}" if week_start else "按计划 Markdown 中的小周期导出"
    headers = ["日期/Day", "顺序", "动作", "计划剂量", "RPE/RIR", "休息", "替代动作", "完成状态", "实际重量×次数 / 备注"]
    table_data = [[paragraph(value, header_style) for value in headers]]
    table_data.extend([[paragraph(value, cell_style) for value in row] for row in rows])
    table = Table(table_data, colWidths=[23 * mm, 10 * mm, 37 * mm, 27 * mm, 19 * mm, 15 * mm, 31 * mm, 24 * mm, 53 * mm], repeatRows=1, hAlign="LEFT")
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#17324D")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#CBD5E1")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 2.2), ("RIGHTPADDING", (0, 0), (-1, -1), 2.2),
        ("TOPPADDING", (0, 0), (-1, -1), 2.2), ("BOTTOMPADDING", (0, 0), (-1, -1), 2.2),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAFC")]),
    ]))
    footer = paragraph("实际完成情况留白供记录；未确认的训练不自动标为 completed。出现疼痛、头晕、胸闷或动作质量明显下降时停止该组并记录。", small_style)
    document.build([
        paragraph(f"{week_label}训练计划", title_style),
        paragraph(f"周范围：{week_text}　目标：{metadata.get('goal', 'unknown')}　计划版本：{metadata.get('plan_version', 'unknown')}　来源：{plan_path.name}", meta_style),
        Spacer(1, 3 * mm), table, Spacer(1, 3 * mm), footer,
    ])
    return len(rows)


def main() -> int:
    args = parse_args()
    return 0 if build_pdf(args.plan, args.output, parse_week_start(args.week_start), args.week_label) else 1


if __name__ == "__main__":
    sys.exit(main())
