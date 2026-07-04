# BudgetSentinel: Government Public Project Expenditure Tracking and Anomaly Detection System

---

## 1. Project Overview

| | |
|---|---|
| **Project Title** | BudgetSentinel: Government Public Project Expenditure Tracking and Anomaly Detection System |
| **Project Type** | Artificial Intelligence Web-Based System |
| **Domain** | Public Financial Management and Government Accountability |
| **Architecture** | Microservice Architecture |

---

## 2. Background and Problem Statement

Public financial management across East Africa continues to face significant challenges, with billions in government funds allocated to infrastructure, education, and health projects failing to translate into completed deliverables. Governments publish procurement records and project budgets, yet no intelligent system exists to continuously monitor whether actual spending aligns with approved milestones and contracts.

The absence of real-time expenditure monitoring systems, combined with manual and fragmented auditing processes, creates conditions in which procurement fraud, duplicate payments, inflated contracts, and project abandonment go undetected until public resources are irreversibly lost. Auditors work reactively, reviewing records long after irregularities have occurred, and oversight bodies receive reports too late to intervene effectively.

Furthermore, the sheer volume of procurement documents, financial records, and expenditure reports makes manual review impractical for human auditors working within limited timeframes and resources. Patterns that span multiple projects, contractors, and time periods remain invisible to traditional auditing approaches, allowing systematic fraud to persist undetected across government financial systems.

Rwanda, despite being one of Africa's most digitally progressive nations, faces this same challenge. The Rwanda Public Procurement Authority publishes procurement reports, yet no automated intelligence layer exists to continuously monitor expenditure patterns, detect irregularities, and alert oversight bodies in real time.

BudgetSentinel addresses this gap by providing an intelligent, automated system that monitors public project expenditures, applies machine learning based anomaly detection to flag suspicious patterns, and delivers real-time alerts and AI-generated audit reports to oversight authorities before funds are irreversibly lost.

---

## 3. Problem Statement

Government public project expenditure monitoring in Rwanda and across East Africa relies predominantly on manual auditing processes that are reactive, slow, and incapable of detecting complex fraud patterns across large volumes of financial data. This results in the systematic loss of public funds through procurement irregularities, duplicate payments, inflated contracts, and project abandonment that go undetected until significant damage has already occurred. There is a critical need for an intelligent, real-time expenditure monitoring system capable of automatically detecting anomalies, generating audit intelligence, and alerting oversight authorities proactively.

---

## 4. Project Objectives

The following are the key objectives of the BudgetSentinel system:

1. To design and develop an intelligent web-based system that ingests and tracks government public project expenditure data against approved budgets and milestones.
2. To implement a machine learning based anomaly detection algorithm capable of identifying procurement fraud patterns, duplicate payments, inflated contracts, and unusual expenditure spikes automatically.
3. To integrate a large language model API to generate intelligent, context-aware audit reports summarizing detected anomalies and recommending corrective actions for oversight authorities.
4. To develop a real-time visual analytics dashboard using Phoenix LiveView that enables government administrators and auditors to monitor project financial health and view anomaly alerts without manual page refresh.
5. To implement an automated alert system that dispatches AI-generated audit notifications to designated oversight officers upon detection of high-risk anomalies.
6. To evaluate the accuracy and effectiveness of the anomaly detection model against known fraud patterns embedded within a realistic simulated Rwanda government expenditure dataset.

---

## 5. Proposed System Description

BudgetSentinel is an AI-powered web-based platform built on a microservice architecture that separates web orchestration from AI computation, designed to bring transparency, accountability, and predictive oversight to government public project funding. The system operates across two core services:

### 5.1 Elixir Phoenix Service
The primary web service built with Elixir Phoenix handles all user-facing operations including real-time dashboard management, database operations, and alert dispatching. Phoenix LiveView powers the real-time dashboard, automatically pushing anomaly results and expenditure updates to all connected users the moment they are detected without requiring a page refresh. Phoenix PubSub manages broadcast communication across connected dashboard sessions, ensuring all stakeholders receive anomaly alerts simultaneously.

### 5.2 Python AI Microservice
A dedicated Python Flask microservice handles all artificial intelligence and machine learning workloads in isolation from the web layer. This service receives expenditure data forwarded by the Elixir service, runs Isolation Forest anomaly detection models, calculates contractor risk scores, and integrates with the Claude API to generate intelligent audit report summaries. Results are returned to the Elixir service via HTTP and immediately broadcast to the live dashboard.

### 5.3 Data Layer
BudgetSentinel operates on a realistic simulated dataset of Rwanda government project expenditures modeled on publicly available Rwanda Public Procurement Authority reports and procurement records. The dataset includes fifty government projects across sectors including infrastructure, education, and health, two hundred expenditure records, and ten embedded fraud scenarios representing known procurement irregularity patterns. This approach ensures the system can be fully demonstrated, tested, and evaluated without dependency on government API access, while the architecture is designed to accommodate direct integration with live systems such as Rwanda IFMIS and the RPPA portal once public API access becomes available.

### 5.4 Anomaly Detection Layer
The Isolation Forest machine learning algorithm analyzes expenditure records against approved project budgets and historical baseline patterns to identify anomalies including payments processed for incomplete project milestones, expenditure amounts significantly exceeding approved budgets, duplicate contractor payment patterns, and unusual expenditure spikes within short time windows. Each detected anomaly is assigned a numerical risk score enabling prioritization of audit interventions.

### 5.5 Reporting and Alert Layer
Upon detecting anomalies, the Python microservice calls the Claude API to generate structured, context-aware audit reports summarizing the nature, severity, and financial impact of each irregularity alongside recommended corrective actions. High-risk anomaly reports are automatically dispatched to designated oversight officers via email. The real-time LiveView dashboard displays all anomalies, risk scores, and audit reports in a visual analytics interface accessible to authorized government administrators and auditors.

---

## 6. Key Features

| Feature | Description |
|---|---|
| **Expenditure Tracking** | Monitors government project spending against approved budgets and milestones |
| **ML Anomaly Detection** | Isolation Forest model automatically detects fraud patterns and expenditure irregularities |
| **Risk Scoring** | Assigns numerical risk scores to flagged transactions for audit prioritization |
| **AI Audit Report Generation** | Claude API generates intelligent, context-aware audit summaries for each detected anomaly |
| **Real-Time Live Dashboard** | Phoenix LiveView updates dashboard instantly when anomalies are detected without page refresh |
| **Multi-Project Monitoring** | Monitors multiple government projects simultaneously on a single platform |
| **Automated Email Alerts** | Dispatches audit reports to oversight officers automatically for high-risk anomalies |
| **Anomaly History Tracking** | Maintains a searchable record of all detected anomalies and generated audit reports |

---

## 7. System Architecture

```
+--------------------------------------------------+
|              User Browser                        |
|   Government Administrators and Auditors         |
+------------------------+-------------------------+
                         |
                         | HTTPS
                         v
+--------------------------------------------------+
|       Elixir Phoenix + LiveView Service          |
|                                                  |
|  - Real-Time Dashboard (Phoenix LiveView)        |
|  - Live Anomaly Broadcast (Phoenix PubSub)       |
|  - Database Management (PostgreSQL via Ecto)     |
|  - Automated Email Alerts (Swoosh)               |
|  - Expenditure Data Management                   |
|  - Anomaly and Report Storage                    |
+------------------------+-------------------------+
                         |
                         | Internal HTTP Calls
                         | (when analysis is triggered)
                         v
+--------------------------------------------------+
|         Python Flask AI Microservice             |
|                                                  |
|  - Isolation Forest Anomaly Detection            |
|  - Risk Score Calculation                        |
|  - Claude API Integration (Audit Reports)        |
+------------------------+-------------------------+
                         |
                         v
+--------------------------------------------------+
|         Data and External Services               |
|                                                  |
|  Simulated Rwanda Expenditure Dataset            |
|  Claude API (AI Report Generation)               |
|  Gmail API (Email Alert Dispatch)                |
+--------------------------------------------------+
```

---

## 8. Technologies and Tools

### 8.1 Elixir Phoenix Service

| Technology | Purpose |
|---|---|
| **Elixir** | Primary backend language for the web service |
| **Phoenix Framework** | Web application framework and routing |
| **Phoenix LiveView** | Real-time dashboard without JavaScript frameworks |
| **Phoenix PubSub** | Live broadcast of anomaly alerts to connected users |
| **Swoosh** | Automated email alert dispatch to oversight officers |
| **Ecto** | Database interaction and query management |
| **PostgreSQL** | Primary relational database |

### 8.2 Python AI Microservice

| Technology | Purpose |
|---|---|
| **Python** | Primary language for AI and machine learning workloads |
| **Flask** | Lightweight web framework exposing AI endpoints to Elixir |
| **Scikit-learn** | Isolation Forest anomaly detection model training and inference |
| **Pandas** | Expenditure data processing and transformation |
| **NumPy** | Numerical computation for risk score calculation |
| **Claude API** | Intelligent audit report generation via large language model |

### 8.3 External Services

| Service | Purpose |
|---|---|
| **Claude API** | AI-powered audit report generation and anomaly summarization |
| **Gmail API** | Automated dispatch of audit alert emails to oversight officers |

---

## 9. Database Design Overview

The PostgreSQL database is managed through the Elixir Ecto layer with the following core tables:

| Table | Description |
|---|---|
| **projects** | Government public projects with names, sectors, approved budgets, and milestones |
| **expenditures** | Individual expenditure records linked to projects including amounts, dates, and contractors |
| **anomalies** | Detected anomalies with type, severity level, risk score, and detection timestamp |
| **audit_reports** | AI-generated audit reports linked to detected anomalies |
| **alerts** | Alert records tracking email dispatch status to oversight officers |

---

## 10. Methodology

The project follows the **Agile Software Development Methodology** with iterative development cycles divided into the following phases:

### Phase 1: Requirements Analysis (Weeks 1–2)
- Define anomaly types and detection criteria based on known procurement fraud patterns
- Design simulated Rwanda expenditure dataset structure and embedded fraud scenarios
- Identify system users, roles, and dashboard requirements
- Document functional and non-functional system requirements

### Phase 2: System Design (Weeks 3–4)
- Design microservice architecture and inter-service HTTP communication protocol
- Design PostgreSQL database schema and entity relationships
- Design machine learning model pipeline and anomaly scoring approach
- Design Phoenix LiveView dashboard wireframes and user interface layouts

### Phase 3: Development (Weeks 5–10)
- Set up Elixir Phoenix project structure and PostgreSQL database with Ecto
- Develop Phoenix LiveView real-time dashboard and PubSub broadcast system
- Set up Python Flask microservice and expose anomaly detection endpoints
- Generate realistic simulated Rwanda government expenditure dataset
- Train and validate Isolation Forest anomaly detection model on simulated dataset
- Integrate Claude API for intelligent audit report generation
- Implement automated email alert system via Swoosh and Gmail API
- Establish HTTP communication layer between Elixir and Python services
- Connect all system components end to end

### Phase 4: Testing (Weeks 11–12)
- Unit testing of individual Elixir and Python components
- Integration testing across microservice communication layer
- Anomaly detection accuracy evaluation against ten embedded fraud scenarios in simulated dataset
- Real-time dashboard performance and broadcast testing
- End to end system testing covering full flow from expenditure ingestion to alert dispatch

### Phase 5: Deployment and Documentation (Weeks 13–14)
- Deploy complete system for demonstration
- Prepare full system documentation and user manual
- Prepare final project report and presentation

---

## 11. Data Sources and Limitations

### 11.1 Data Approach
Due to the limited availability of publicly accessible government procurement APIs in Rwanda, BudgetSentinel utilizes a realistic simulated dataset of Rwanda government project expenditures as its primary data source. The dataset is modeled on publicly available Rwanda Public Procurement Authority procurement reports and structured to reflect real expenditure patterns across government sectors including infrastructure, education, and health. Ten known fraud scenarios are embedded within the dataset to enable rigorous evaluation of the anomaly detection model's accuracy and recall performance.

### 11.2 Embedded Fraud Scenarios
The simulated dataset includes the following fraud pattern types for model evaluation:

| Fraud Type | Description |
|---|---|
| **Budget Overrun** | Payments significantly exceeding approved project budget |
| **Duplicate Payment** | Same contractor paid multiple times for the same milestone |
| **Ghost Project** | Full payment disbursed for project with zero completion |
| **Inflated Contract** | Contract value far above market benchmark for project type |
| **Premature Payment** | Full payment released before project milestone is achieved |

### 11.3 Production Roadmap
The system architecture is designed to accommodate direct integration with live government financial systems including Rwanda IFMIS, the Rwanda Public Procurement Authority portal, the Open Contracting Data Standard API, and the World Bank Procurement API once public access becomes available. This reflects Rwanda's ongoing digital governance transformation agenda and positions BudgetSentinel as a production-ready solution awaiting API ecosystem maturity.

---

## 12. Expected Outcomes

Upon completion, BudgetSentinel is expected to deliver the following outcomes:

1. A fully functional web-based system built on a microservice architecture capable of monitoring and analyzing government project expenditure data in real time.
2. A trained Isolation Forest anomaly detection model with measurable precision and recall performance evaluated against ten embedded fraud scenarios in the simulated dataset.
3. A real-time Phoenix LiveView dashboard that automatically updates all connected users with detected anomalies and risk scores without manual page refresh.
4. An AI-powered audit report generation system producing intelligent, context-aware summaries of detected anomalies using the Claude API.
5. An automated email alert system dispatching high-risk anomaly reports to designated oversight officers immediately upon detection.
6. A comprehensive evaluation report demonstrating the system's anomaly detection accuracy, response time, and audit report quality against defined performance benchmarks.

---

## 13. Significance of the Project

BudgetSentinel addresses one of the most persistent and costly challenges in public governance across East Africa — the loss of public funds through undetected procurement fraud and inadequate expenditure monitoring. By combining machine learning anomaly detection, large language model integration, and real-time web technology, the system moves public financial oversight from reactive auditing to proactive, intelligence-driven monitoring.

The project's microservice architecture, separating Elixir Phoenix LiveView web orchestration from Python AI computation, reflects industry-standard approaches used by real-world financial technology and government technology organizations for building scalable, maintainable intelligent systems. This architectural decision demonstrates advanced software engineering practice while ensuring AI workloads remain independently scalable and maintainable.

The use of a realistic simulated dataset rather than live government APIs is a deliberate and transparent academic design decision that enables rigorous model evaluation through controlled fraud scenarios while maintaining the system's readiness for production deployment. This approach is consistent with established practices in academic machine learning research where controlled datasets enable reproducible and measurable evaluation.

BudgetSentinel contributes to the fields of artificial intelligence, public financial management, and e-governance, and demonstrates the practical application of modern AI technologies to real-world accountability challenges facing Rwandan and East African governments and citizens.

---

## 14. Conclusion

BudgetSentinel represents a timely and impactful application of artificial intelligence and modern web technology to public financial governance. The system directly addresses the gap between government procurement records and real-time accountability, providing oversight bodies with the intelligent tools needed to detect fraud patterns, prevent fund misappropriation, and ensure that government projects deliver intended value to citizens.

Through the integration of a real-time Elixir Phoenix LiveView interface, a dedicated Python AI microservice, Isolation Forest anomaly detection, Claude API powered audit report generation, and automated email alerting, BudgetSentinel delivers a complete, defensible, and professionally architected intelligent system that demonstrates both strong technical capability and genuine real-world impact.

---

*Prepared for Academic Project Submission*
