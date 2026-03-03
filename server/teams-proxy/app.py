import os
import requests
from fastapi import FastAPI, Request

app = FastAPI()

TEAMS_URL = os.environ.get("TEAMS_WEBHOOK_URL")


@app.post("/webhook")
async def webhook(request: Request):
    data = await request.json()

    for alert in data.get("alerts", []):
        summary = alert["annotations"].get("summary", "")
        description = alert["annotations"].get("description", "")

        payload = {
            "@type": "MessageCard",
            "@context": "http://schema.org/extensions",
            "summary": alert["labels"].get("alertname"),
            "themeColor": "FF0000"
            if alert["labels"].get("severity") == "critical"
            else "FFA500",
            "title": f"🚨 {alert['labels'].get('alertname')}",
            "text": f"**Severity:** {alert['labels'].get('severity')}\n\n"
                    f"**Summary:** {summary}\n\n"
                    f"**Details:** {description}"
        }

        requests.post(
            TEAMS_URL,
            headers={"Content-Type": "application/json"},
            json=payload,
            timeout=10,
        )

    return {"status": "ok"}