\# NHS Elective Care Performance \& Backlog Recovery Analytics



This project analyses NHS elective care waiting-list performance using Python, SQL Server and Power BI.



The aim was to build an end-to-end analytics project that cleans monthly NHS RTT data, creates a SQL star schema, and presents the results through an interactive Power BI report for backlog monitoring and recovery planning.



\---



\## Project Overview



NHS elective care waiting lists are an important operational area because they show how many patients are still waiting for treatment.



This project focuses on:



\- Total waiting list size

\- 18-week performance

\- Gap to the 92% target

\- 52+ week waits

\- Provider pressure

\- Specialty pressure

\- Regional variation

\- Backlog recovery scenarios

\- Provider-level performance trends



The final report is designed as a management-style Power BI dashboard with navigation, slicers, reset buttons and a recovery simulator.



\---



\## Tools Used



\- Python

\- SQL Server

\- Power BI

\- Excel / CSV



\---



\## Project Structure



```text

NHS Elective Care Performance \& Backlog Recovery Analytics

│

├── 02\_python

│   └── 01\_combine\_clean\_rtt\_data.ipynb

│

├── 04\_clean\_data

│   └── clean\_rtt\_summary\_data.csv

│

├── 05\_sql

│   ├── 01\_create\_database\_and\_staging\_table.sql

│   ├── 02\_staging\_data\_validation.sql

│   ├── 03\_create\_star\_schema.sql

│   └── 04\_create\_analysis\_views.sql

│

├── 06\_power\_bi

│   └── NHS\_Elective\_Care\_Analytics.pbix

│

├── 08\_screenshots

│   ├── 01\_executive\_overview.png

│   ├── 02\_provider\_specialty.png

│   ├── 03\_recovery\_simulator.png

│   └── 04\_provider\_profile.png

│

└── README.md

