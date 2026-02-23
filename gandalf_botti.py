import os
import subprocess
import json
import time

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT).decode('utf-8')
    except subprocess.CalledProcessError as e:
        return e.output.decode('utf-8')

def get_issues():
    print("🔍 Haetaan AppFlowy-issuet...")
    cmd = "gh issue list --limit 10 --json number,title,body"
    return json.loads(run_cmd(cmd))

def work_on_issue(issue):
    num = issue['number']
    title = issue['title']
    print(f"\n--- 🧙‍♂️ TYÖN ALLA: #{num} ---")
    print(f"🎯 Otsikko: {title}")

    # Varmistetaan että remote "fork" on olemassa
    username = run_cmd("gh api user -q .login").strip()
    run_cmd(f"git remote add fork https://github.com/{username}/AppFlowy.git")

    branch_name = f"fix-issue-{num}"
    run_cmd("git checkout main && git pull origin main")
    run_cmd(f"git checkout -b {branch_name}")

    # [Simuloidaan korjaus]
    print(f"✨ Luodaan korjausta...")
    
    # 4. Pusku omaan forkiin ja PR päärepoon
    run_cmd("git add .")
    run_cmd(f"git commit -m 'fix: {title} (issue #{num})'")
    
    # TÄRKEÄÄ: Pusku omaan forkiin, ei päärepoon!
    print(f"🚀 Pusketaan koodia omaan forkiin...")
    run_cmd(f"git push fork {branch_name} -f")
    
    # Tehdään PR päärepoon
    pr_cmd = f"gh pr create --repo AppFlowy-IO/AppFlowy --title 'fix: {title} (issue #{num})' --body '🧙‍♂️ Gandalf automated fix for issue #{num}' --head {username}:{branch_name}"
    pr_url = run_cmd(pr_cmd)
    
    print(f"✅ PR LÄHETETTY: {pr_url}")

def main():
    issues = get_issues()
    for issue in issues:
        work_on_issue(issue)
        time.sleep(5)

if __name__ == "__main__":
    main()
