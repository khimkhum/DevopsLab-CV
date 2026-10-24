import base64
import getpass
import json
from pathlib import Path

username = "robot$cv+deploy-pull"
secret = getpass.getpass("Secret robot deploy-pull: ")
if not secret:
    raise SystemExit("Secret không được để trống")

auth = base64.b64encode(
    f"{username}:{secret}".encode()
).decode()

path = Path(".secrets/k8s/harbor-pull.json")
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(
    json.dumps({
        "auths": {
            "harbor.cv.test:8443": {"auth": auth}
        }
    }) + "\n",
    encoding="utf-8",
)
print("Đã ghi cấu hình pull Harbor trong .secrets.")
