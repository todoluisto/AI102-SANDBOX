"""Gap analyzer using Azure OpenAI structured outputs.

Compares a resume profile against a job description to identify
matched skills, missing skills, and bonus skills the candidate brings.
"""

import json
import logging
from pathlib import Path
from typing import Literal

from jinja2 import Template
from pydantic import BaseModel

from .job_analyzer import _build_client

logger = logging.getLogger(__name__)

PROMPTS_DIR = Path(__file__).parent.parent / "prompts"


class SkillGap(BaseModel):
    """A single skill/qualification with context."""

    name: str
    category: Literal["technical", "domain", "soft_skill", "certification", "tool"]
    detail: str


class GapAnalysisResult(BaseModel):
    """Structured output for gap analysis."""

    matched_skills: list[SkillGap]
    missing_skills: list[SkillGap]
    bonus_skills: list[SkillGap]
    summary: str
    recommendations: list[str]


def _load_gap_template() -> Template:
    """Load the gap analysis prompt template."""
    template_path = PROMPTS_DIR / "gap_analysis.txt"
    return Template(template_path.read_text())


def _call_openai_gap(client, deployment_name: str, system_prompt: str, user_prompt: str) -> GapAnalysisResult:
    """Make the gap analysis call and parse the result."""
    try:
        response = client.beta.chat.completions.parse(
            model=deployment_name,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            response_format=GapAnalysisResult,
            temperature=0.2,
        )
        result = response.choices[0].message.parsed
        logger.info(
            "Gap analysis (structured) — tokens: %d input, %d output",
            response.usage.prompt_tokens,
            response.usage.completion_tokens,
        )
        return result
    except Exception as e:
        logger.warning("Structured outputs failed (%s), falling back to json_object mode", e)

        response = client.chat.completions.create(
            model=deployment_name,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            response_format={"type": "json_object"},
            temperature=0.2,
        )
        raw = json.loads(response.choices[0].message.content)
        logger.info(
            "Gap analysis (json_object) — tokens: %d input, %d output",
            response.usage.prompt_tokens,
            response.usage.completion_tokens,
        )
        return GapAnalysisResult(**raw)


def analyze_gap(
    resume_profile_text: str,
    job_description: str,
    primary_endpoint: str,
    primary_key: str | None = None,
    primary_deployment: str = "gpt-4o-mini",
    fallback_endpoint: str | None = None,
    fallback_key: str | None = None,
    fallback_deployment: str = "gpt-4o-mini",
    use_identity: bool = False,
) -> GapAnalysisResult:
    """Analyze skills gaps between a resume profile and job description.

    Tries the primary Azure OpenAI endpoint first. Falls back to
    the secondary endpoint if the primary fails.
    """
    template = _load_gap_template()
    rendered = template.render(
        resume_profile=resume_profile_text,
        job_description=job_description,
    )

    parts = rendered.split("---", 1)
    system_prompt = parts[0].strip()
    user_prompt = parts[1].strip() if len(parts) > 1 else rendered

    try:
        client = _build_client(primary_endpoint, primary_key, use_identity)
        result = _call_openai_gap(client, primary_deployment, system_prompt, user_prompt)
        logger.info("Gap analysis succeeded on primary endpoint")
        return result
    except Exception as e:
        logger.warning("Primary endpoint failed for gap analysis: %s", e)
        if not fallback_endpoint:
            raise

    logger.info("Retrying gap analysis with fallback endpoint")
    client = _build_client(fallback_endpoint, fallback_key, use_identity)
    result = _call_openai_gap(client, fallback_deployment, system_prompt, user_prompt)
    logger.info("Gap analysis succeeded on fallback endpoint")
    return result
