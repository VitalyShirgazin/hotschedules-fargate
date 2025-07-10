# 🕒 Hotschedules Break Automation (AWS Fargate)

## ✅ What It Does

1. **Daily Login to WebClock**  
   Logs in every day at a specified time to [HotSchedules WebClock](https://app.hotschedules.com/hs/webclock/), using user-provided credentials.

2. **Clock-In Check**  
   Checks whether the user has already clocked in for the day.  
   - If **not clocked in**, the script exits.  
   - If **clocked in**, it proceeds to Step 3.

3. **Start and End Break Automatically**  
   Triggers a break start and end, exactly 45 minutes apart.

4. **Email Notifications**  
   Sends instant email notifications to both:  
   - The **administrator**  
   - The **account owner**  
   (based on emails configured during account setup)

5. **Scalable for Multiple Users**  
   Each user gets their own separate infrastructure.

---

## ☁️ Cloud Deployment: `DEPLOY.sh`

This script launches and deploys the entire infrastructure to AWS Cloud using Terraform:

- Creates an **ECR** repository  
- Builds **two Docker containers** (`break-in`, `break-out`)  
- Pushes Docker images to AWS ECR  
- Sets up **AWS EventBridge schedulers**  
- Defines **AWS IAM roles and policies**  
- Deletes local Docker images after pushing

---

### `break_in.py`  
Logs into HotSchedules and starts the break.

### `break_out.py`  
Logs into HotSchedules and ends the break after 45 minutes.

---

## 👤 User Management

### `ADD_USER.sh`  
Creates a new user account and deploys the break automation:  
- Break-in AWS ECS task + scheduler  
- Break-out AWS ECS task + scheduler  
- AWS IAM roles and permissions

### `DELETE_USER.sh`  
Deletes a user and all associated AWS Cloud infrastructure.

### `UNDEPLOY.sh`  
Removes the **entire** application from AWS Cloud.  
If users still exist, it deletes them first before tearing down the base infrastructure.

---

## ⚠️ Notes

- Replace all `CHANGE_ME` placeholders in the files with your real values.  
- You need an active **AWS account** to use this app.  
- Works with any SMTP provider, but tested using **Gmail** (see below).

---

## 🔐 Gmail App Password (Not Your Real Gmail Password!)

This app uses a [Gmail App Password](https://support.google.com/accounts/answer/185833?hl=en), not your actual Gmail password.

### Steps:

1. Go to: [https://myaccount.google.com/security](https://myaccount.google.com/security)  
2. Enable **2-Step Verification**  
3. Scroll to **App passwords**  
4. Create one (e.g., for “Python script”)  
5. Use the **16-character code** (e.g., `kjdgtub642cji9k4`) as your Gmail password in the script

---

## 🚀 Program Startup Sequence

1. Run `DEPLOY.sh` (requires Docker daemon to be running)  
2. Run `ADD_USER.sh` (to add a new user)  
3. Run `DELETE_USER.sh` (to remove a user)  
4. Run `UNDEPLOY.sh` to uninstall the entire app  
   *(No need to delete users manually — the script handles it)*

