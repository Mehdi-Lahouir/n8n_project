import json
import sys
from datetime import datetime, timezone


def main() -> int:
    payload = {
        "message": "hello from the n8n python runner",
        "args": sys.argv[1:],
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    print(json.dumps(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
