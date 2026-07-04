from anthropic import Anthropic

from app.domain.entities import AnomalyResult, ExpenditureRecord, ProjectContext

_SYSTEM_PROMPT = (
    "You are a public financial audit analyst for a government oversight body. "
    "Given a detected expenditure anomaly, write a structured, factual audit report. "
    "Be concise, avoid speculation beyond the given data, and always include concrete "
    "recommended corrective actions. Respond in three labeled sections: "
    "SUMMARY, SEVERITY ASSESSMENT, RECOMMENDED ACTIONS."
)


class AuditReportService:
    def __init__(self, api_key: str, model: str):
        self._model = model
        self._client = Anthropic(api_key=api_key) if api_key else None

    def generate(
        self,
        anomaly: AnomalyResult,
        project: ProjectContext,
        expenditure: ExpenditureRecord,
    ) -> dict:
        if self._client is None:
            return self._fallback_report(anomaly, project, expenditure)

        prompt = self._build_prompt(anomaly, project, expenditure)
        message = self._client.messages.create(
            model=self._model,
            max_tokens=600,
            system=_SYSTEM_PROMPT,
            messages=[{"role": "user", "content": prompt}],
        )
        text = "".join(block.text for block in message.content if block.type == "text")
        return self._parse_sections(text)

    @staticmethod
    def _build_prompt(
        anomaly: AnomalyResult, project: ProjectContext, expenditure: ExpenditureRecord
    ) -> str:
        return (
            f"Project: {project.id} (sector: {project.sector}, "
            f"approved budget: {project.approved_budget}, "
            f"reported completion: {project.completion_rate}%)\n"
            f"Expenditure: {expenditure.amount} paid to {expenditure.contractor} "
            f"for milestone '{expenditure.milestone}' on {expenditure.date}\n"
            f"Detected fraud type: {anomaly.fraud_type}\n"
            f"Risk score: {anomaly.risk_score}/100 (severity: {anomaly.severity})\n"
            f"Detection rationale: {anomaly.explanation}\n"
        )

    @staticmethod
    def _parse_sections(text: str) -> dict:
        sections = {"summary": "", "severity_assessment": "", "recommended_actions": ""}
        current = None
        for line in text.splitlines():
            stripped = line.strip()
            upper = stripped.upper()
            if upper.startswith("SUMMARY"):
                current = "summary"
                continue
            if upper.startswith("SEVERITY ASSESSMENT"):
                current = "severity_assessment"
                continue
            if upper.startswith("RECOMMENDED ACTIONS"):
                current = "recommended_actions"
                continue
            if current and stripped:
                sections[current] = (sections[current] + " " + stripped).strip()
        return sections

    @staticmethod
    def _fallback_report(
        anomaly: AnomalyResult, project: ProjectContext, expenditure: ExpenditureRecord
    ) -> dict:
        return {
            "summary": (
                f"A {anomaly.fraud_type.replace('_', ' ')} anomaly was detected for a payment "
                f"of {expenditure.amount} to {expenditure.contractor} on project {project.id}. "
                f"{anomaly.explanation}"
            ),
            "severity_assessment": (
                f"Risk score {anomaly.risk_score}/100, classified as {anomaly.severity} severity."
            ),
            "recommended_actions": (
                "Suspend further disbursements to this contractor pending manual audit; "
                "verify milestone completion evidence; cross-check payment history for duplicates."
            ),
        }
