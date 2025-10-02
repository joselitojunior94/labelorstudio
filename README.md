<p align="center">
  <img src="images/logo_without_background.png" width="450" alt="Logo"/>
</p>

<p align="center">
  <!-- Repo -->
  <a href="https://github.com/joselitojunior94/labelorstudio/">
    <img alt="Stars" src="https://img.shields.io/github/stars/joselitojunior94/labelorstudio?style=for-the-badge&color=0C6CF2&logo=github">
  </a>
  <a href="https://github.com/joselitojunior94/labelorstudio/fork">
    <img alt="Forks" src="https://img.shields.io/github/forks/joselitojunior94/labelorstudio?style=for-the-badge&color=14B8A6&logo=github">
  </a>
  <a href="https://github.com/joselitojunior94/labelorstudio/issues">
    <img alt="Issues" src="https://img.shields.io/github/issues/joselitojunior94/labelorstudio?style=for-the-badge&color=F59E0B&logo=github">
  </a>
  <a href="https://github.com/joselitojunior94/labelorstudio/pulls">
    <img alt="PRs" src="https://img.shields.io/badge/PRs-Welcome-22c55e?style=for-the-badge&logo=gitbook&logoColor=white">
  </a>
  <br/>
  <!-- Stack -->
  <img alt="Flutter" src="https://img.shields.io/badge/Frontend-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white">
  <img alt="Django REST" src="https://img.shields.io/badge/Backend-Django%20REST-092E20?style=for-the-badge&logo=django&logoColor=white">
  <img alt="Auth" src="https://img.shields.io/badge/Auth-JWT-7834F5?style=for-the-badge&logo=jsonwebtokens&logoColor=white">
  <img alt="License" src="https://img.shields.io/badge/License-MPL%202.0-orange?style=for-the-badge&logo=mozilla&logoColor=white">
  <br/>
  <!-- CI/CD (exemplos) -->
  <img alt="Coverage" src="https://img.shields.io/badge/Coverage-90%25-06B6D4?style=for-the-badge&logo=codecov&logoColor=white">
  <img alt="Pages" src="https://img.shields.io/badge/GitHub%20Pages-Live-0ea5e9?style=for-the-badge&logo=githubpages&logoColor=white">
</p>


## 🎬 Video (Demo)

[![Watch the demo](https://img.shields.io/badge/▶️%20Watch%20Demo-8B5CF6?style=for-the-badge&logo=youtube&logoColor=white)](https://youtu.be/jJqE0kXNyu4)
[![🚀  Open the online tool](https://img.shields.io/badge/🚀%20Testar%20Ferramenta-1DA1F2?style=for-the-badge&logo=github&logoColor=white)]([https://youtu.be/jJqE0kXNyu4](https://labelorstudio.netlify.app/))


## ✨ What is this?
**Labelor Studio** is a full-stack tool to orchestrate human assessments over structured data (CSV).  
It enables researchers, developers, and teams to **upload datasets, invite collaborators, and collect judgments/reviews** — with automatic agreement metrics like **Cohen’s κ**.

### 🔑 Why it matters?
- 📊 **General-purpose**: works with *any* tabular dataset (issues, CI/CD logs, vulnerability reports, papers, surveys, etc).  
- 👥 **Collaboration**: multiple roles — Owner, Judge, Reviewer, Viewer.  
- ⚡ **Automation**: integrates with LLMs to pre-label or suggest judgments.  
- 📈 **Metrics**: compute inter-rater reliability to validate results.  
- 📤 **Export**: get clean CSV/JSON for research or production pipelines.

## 🖼️ Screenshots (Demo)
<p align="center">
  <img src="images/image1.png" width="350" />
  <img src="images/image2.png" width="350" />
  <img src="images/image3.png" width="350" />
  <img src="images/image31.png" width="350" />
  <img src="images/image4.png" width="350" />
  <img src="images/image5.png" width="350" />
  <img src="images/image6.png" width="350" />
  <img src="images/image7.png" width="350" />
</p>

## 🏗️ Architecture

<p align="center">
  <img src="images/architecture.png" width="650" alt="Logo"/>
</p>

## 🚀 Quickstart

### For Offline use

#### Run the back-end

```bash
git clone https://github.com/joselitojunior94/labelorstudio.git

cd api

python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt

python manage.py migrate
python manage.py createsuperuser
python manage.py runserver

```

#### Run the front-end

```bash
cd ../labelor_studio_app
flutter pub get

# set your backend URL in kApiBaseUrl
flutter run -d chrome

flutter build web

```

## ⚙️ Features

 - 📂 Upload & Merge CSVs
 - 🧩 Column Mapping Wizard
 - 👤 User Roles (Owner, Judge, Reviewer, Viewer)
 - 📝 Judgment & Review Workflows
 - 🤖 Optional LLM Automation
 - 📊 Reliability Metrics (Cohen’s κ)
 - 📤 Export to CSV/JSON

## 🧪 Example Use Cases
 - 🐞 GitHub Issue Labeling (defects, enhancements, questions)
 - 🔐 CI/CD Vulnerability Reports (severity triage)
 - 📚 Paper Classification (systematic mapping)
 - 🧑‍🏫 Educational Data (grading / rubric-based evaluation)

## 📊 REST API (endpoints)

 - POST /api/auth/register/                  # create user
 - POST /api/datasets/upload-csv/            # upload dataset
 - POST /api/datasets/{id}/versions/{v}/mapping/   # save mapping
 - POST /api/evaluations/                    # create evaluation
 - POST /api/evaluations/{id}/items/{iid}/judgments/
 - POST /api/evaluations/{id}/items/{iid}/reviews/
 - GET  /api/evaluations/{id}/metrics/       # Cohen's κ
 - GET  /api/evaluations/{id}/export/csv/    # export results

## 🌟 Citation


