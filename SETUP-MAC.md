# Setup on your Mac (one time, ~20 minutes)

## 1. Install the tools
1. **Godot 4** (standard, not .NET): https://godotengine.org/download/macos/ → drag to Applications. First launch: right-click → Open → Open.
2. **Claude desktop app**: https://claude.com/download → sign in.
3. **Git + Git LFS**: open **Terminal** (Cmd+Space, type "Terminal") and run:
   ```
   xcode-select --install
   ```
   Then install Homebrew from https://brew.sh and run:
   ```
   brew install git-lfs
   git lfs install
   ```
4. *(Later)* **Blender**: https://www.blender.org/download/

## 2. Put these files in your folder
Unzip `Kaalchakra.zip` so the files (`CLAUDE.md`, `docs/`, `game/`, …) sit **directly inside** your Kaalchakra folder.

## 3. Send it to GitHub
In Terminal (replace the path with your folder's):
```
cd ~/path/to/your/Kaalchakra
git init
git add .
git commit -m "Project foundation: docs, brief, folder structure"
git branch -M main
git remote add origin https://github.com/NatchsolutionsAdmin/Kaalchakra.git
git push -u origin main
```
If GitHub asks for a password, use a **personal access token** (GitHub → Settings → Developer settings → Tokens), or install GitHub Desktop and do the push from there.

Tip: easier still, let Claude run these commands for you once the folder is connected (step 4).

## 4. Start the Claude session
1. Open the Claude desktop app → start a task and **connect your Kaalchakra folder**.
2. Paste the prompt from `SESSION-PROMPT.md`.
3. Claude reads `CLAUDE.md` and starts the first greybox prototype.

## 5. Moving to Windows later
Install the **same Godot version**, Git for Windows (includes LFS), and the Claude app. Then `git clone https://github.com/NatchsolutionsAdmin/Kaalchakra.git` — done.
