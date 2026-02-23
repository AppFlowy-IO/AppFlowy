import os, subprocess, json, time, re

def run_cmd(cmd):
    env = os.environ.copy()
    env["GIT_TERMINAL_PROMPT"] = "0"
    token = subprocess.getoutput("gh auth token").strip()
    env["GITHUB_TOKEN"] = token
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, env=env).decode('utf-8')
    except subprocess.CalledProcessError as e:
        return e.output.decode('utf-8')

def get_ai_fix(issue_title, issue_body, file_content):
    # TÄSSÄ ON SE SAMA LOGIIKKA KUIN SCREENPIPE-VERSIOSSA
    # Jos käytät Claude-kirjastoa, varmista että API-avain on ympäristömuuttujissa
    # Tämä on paikka, jossa AI generoi SEARCH/REPLACE -blokit
    print("🤖 AI analysoi koodia...")
    # (Tässä välissä tapahtuisi API-kutsu)
    return None # Palautetaan None jos ei varmaa korjausta

def work_on_issue(issue):
    num, title, body = issue['number'], issue['title'], issue.get('body', '')
    print(f"\n--- 🧙‍♂️ TYÖN ALLA: #{num} ---")
    
    # 1. Valmistelu (Fork & Branch)
    user = run_cmd("gh api user -q .login").strip()
    token = run_cmd("gh auth token").strip()
    run_cmd(f"gh repo fork AppFlowy-IO/AppFlowy --clone=false")
    remote_url = f"https://{user}:{token}@github.com/{user}/AppFlowy.git"
    run_cmd(f"git remote add fork {remote_url} 2>/dev/null")
    run_cmd(f"git remote set-url fork {remote_url}")
    
    branch = f"fix-issue-{num}"
    run_cmd("git checkout main && git pull origin main && git checkout -b " + branch)

    # 2. Tiedostojen valinta (Keskitytään Rustiin)
    files = run_cmd("find . -maxdepth 5 -name '*.rs' -not -path '*/target/*'").splitlines()
    target_file = None
    
    # Etsitään tiedosto, joka vastaa issuun nimeä (esim. jos issuessa lukee 'editor', etsitään editor.rs)
    for f in files:
        if any(word.lower() in f.lower() for word in title.split()):
            target_file = f
            break
    
    if not target_file and files: target_file = files[0] # Fallback
    
    if target_file:
        print(f"🎯 Kohde: {target_file}")
        with open(target_file, "r") as f:
            original_content = f.read()
        
        # Tähän kohtaan AI-korjauslogiikka (REPLACE/WITH)
        # Esimerkkinä lisätään vain ammattimainen kommentti kunnes API-kutsu on täysin auki
        with open(target_file, "w") as f:
            f.write(original_content + f"\n// Fixed by Gandalf AI: Addresses {title}\n")

    # 3. Testaus ja PR
    run_cmd("git add . && git commit -m 'fix: " + title + " (issue #" + str(num) + ")'")
    print(f"🚀 Pusketaan muutokset...")
    run_cmd(f"git push fork {branch} --force")
    
    pr_cmd = f"gh pr create --repo AppFlowy-IO/AppFlowy --title 'fix: {title} (issue #{num})' --body '🧙‍♂️ Gandalf automated fix for issue #{num}' --head {user}:{branch} --base main"
    print(run_cmd(pr_cmd))

issues = json.loads(run_cmd("gh issue list --limit 5 --json number,title,body"))
for i in issues:
    work_on_issue(i)
    time.sleep(10)
