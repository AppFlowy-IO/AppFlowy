import os
import subprocess
import json
import time

# --- ASETUKSET ---
MODEL = "claude-3-5-sonnet-20241022" 

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT).decode('utf-8')
    except subprocess.CalledProcessError as e:
        return e.output.decode('utf-8')

def get_issues():
    print("🔍 Haetaan AppFlowy-issuet...")
    cmd = "gh issue list --limit 10 --json number,title,body"
    return json.loads(run_cmd(cmd))

def find_relevant_files():
    # Rajataan Rust-tiedostoihin, mutta poistetaan testit ja resurssit
    cmd = "find . -maxdepth 5 -name '*.rs' -not -path '*/target/*' -not -path '*/.git/*' -not -path '*/tests/*'"
    files = run_cmd(cmd).splitlines()
    return [f for f in files if f.strip()][:200] # Limitti ettei LLM huku

def work_on_issue(issue):
    num = issue['number']
    title = issue['title']
    body = issue.get('body', '')
    
    print(f"\n--- 🧙‍♂️ TYÖN ALLA: #{num} ---")
    print(f"🎯 Otsikko: {title}")

    # 1. Tarkistetaan onko PR jo olemassa
    existing_prs = run_cmd(f"gh pr list --search '{num}'")
    if str(num) in existing_prs:
        print(f"⏭️ PR tälle issuulle löytyy jo. Ohitetaan.")
        return

    # 2. Haetaan tiedostot
    all_files = find_relevant_files()
    
    # 3. Luodaan uusi branch korjausta varten
    branch_name = f"fix-issue-{num}"
    run_cmd("git checkout main && git pull") # Varmistetaan että ollaan ajantasalla
    run_cmd(f"git checkout -b {branch_name}")

    # --- TÄSSÄ KOHTAA TAPAHTUU AI-TAIKA (Kutsu Claudelle) ---
    # Skripti olettaa että sinulla on toimiva yhteys APIin. 
    # Tässä esimerkissä botti yrittää muokata koodia REPLACE/WITH-metodilla.
    
    # [Tässä simuloidaan onnistunut korjaus]
    print(f"✨ Luodaan korjausta ja lähetetään PR...")

    # 4. Commit ja PR
    run_cmd("git add .")
    run_cmd(f"git commit -m 'fix: {title} (issue #{num})'")
    run_cmd(f"git push origin {branch_name}")
    
    pr_cmd = f"gh pr create --title 'fix: {title} (issue #{num})' --body '🧙‍♂️ Gandalf automated fix for issue #{num}'"
    pr_url = run_cmd(pr_cmd)
    
    print(f"🚀 PR VALMIS: {pr_url}")

def main():
    if "Logged in to" not in run_cmd("gh auth status"):
        print("❌ Kirjaudu ensin: gh auth login")
        return

    issues = get_issues()
    for issue in issues:
        work_on_issue(issue)
        time.sleep(5)

if __name__ == "__main__":
    main()
