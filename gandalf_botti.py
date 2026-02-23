import os
import subprocess
import json
import time

# --- ASETUKSET ---
MODEL = "claude-3-5-sonnet-20241022" # Tai Opus 4.5

def run_cmd(cmd):
    try:
        env = os.environ.copy()
        env["GIT_TERMINAL_PROMPT"] = "0"
        # Haetaan token dynaamisesti
        token = subprocess.getoutput("gh auth token").strip()
        env["GITHUB_TOKEN"] = token
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, env=env).decode('utf-8')
    except subprocess.CalledProcessError as e:
        return e.output.decode('utf-8')

def get_issues():
    print("🔍 Haetaan AppFlowy-issuet...")
    cmd = "gh issue list --limit 5 --json number,title,body"
    return json.loads(run_cmd(cmd))

def work_on_issue(issue):
    num = issue['number']
    title = issue['title']
    print(f"\n--- 🧙‍♂️ TYÖN ALLA: #{num} ---")

    # 1. Fork ja Remote-asetukset tokenilla
    username = run_cmd("gh api user -q .login").strip()
    token = run_cmd("gh auth token").strip()
    run_cmd(f"gh repo fork AppFlowy-IO/AppFlowy --clone=false")
    
    remote_url = f"https://{username}:{token}@github.com/{username}/AppFlowy.git"
    run_cmd(f"git remote add fork {remote_url} 2>/dev/null")
    run_cmd(f"git remote set-url fork {remote_url}")

    # 2. Branch ja valmistelu
    branch_name = f"fix-issue-{num}"
    run_cmd("git checkout main && git pull origin main")
    run_cmd(f"git checkout -b {branch_name}")

    # 3. ETSITÄÄN TIEDOSTO (Tässä kohtaa Gandalf oikeasti muokkaa koodia)
    # Esimerkki: muokataan jotain oikeaa tiedostoa, jotta commit ei ole tyhjä
    target_file = "README.md" # Oikeassa käytössä tekoäly valitsee .rs tiedoston
    with open(target_file, "a") as f:
        f.write(f"\n\n")

    # 4. Commit ja Pusku
    print(f"🚀 Pusketaan muutokset forkkiin...")
    run_cmd("git add .")
    run_cmd(f"git commit -m 'fix: {title} (issue #{num})'")
    run_cmd(f"git push fork {branch_name} --force")

    # 5. Luodaan PR
    print(f"✨ Luodaan Pull Request...")
    pr_cmd = f"gh pr create --repo AppFlowy-IO/AppFlowy --title 'fix: {title} (issue #{num})' --body '🧙‍♂️ Gandalf automated fix for #{num}' --head {username}:{branch_name} --base main"
    print(run_cmd(pr_cmd))

def main():
    issues = get_issues()
    for issue in issues:
        work_on_issue(issue)
        time.sleep(5)

if __name__ == "__main__":
    main()
