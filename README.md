# Distributed Database Management on Oracle Servers

## Project Overview

This project involves managing a distributed database across three Oracle servers. The objective is to demonstrate the implementation of a distributed database system using virtual machines (VMs) and Oracle servers, with a central database that is fragmented and synchronized between different sites.

![image](https://github.com/user-attachments/assets/b3782abf-1981-4368-b81b-76833aab170e)

## Prerequisites

Before starting, ensure the following tools and software are installed:

- **Oracle VirtualBox** (Version 5.2.16 or later)
- **Oracle 11g Database**
- **SQL Developer**
- A machine capable of running multiple virtual machines (VMs)

## Virtual Network Setup

### Step 1: Create Virtual Machines

1. Download and install Oracle VirtualBox.
2. Create three virtual machines (VMs) with the following configurations:
   - **Center**
   - **Site1**
   - **Site2**

### Step 2: Install Windows 7 and Oracle 11g

1. Download the Windows 7 ISO image.
2. Install the operating system on each VM.
3. Install Oracle 11g on all three VMs.

### Step 3: Configure the Virtual Network

1. Set up an internal network for the VMs so they can communicate with each other, but not with the physical machine.
2. Assign static IP addresses to each VM:
   - **Center:** 192.168.1.104
   - **Site1:** 192.168.1.102
   - **Site2:** 192.168.1.103
3. Test the network by using the `ping` command between the VMs to ensure connectivity:
*  pinging centre and site 2 from site 1 :
![image](https://github.com/user-attachments/assets/9116f984-ed27-4bc5-ae87-e4776fa66486)


  


## Creating New Database Users

### Step 1: Connect as SYSDBA

For each machine, connect to Oracle as SYSDBA and create new users with administrative privileges.

**Site1:**
```sql
CREATE USER UserSite1 IDENTIFIED BY 1111;
GRANT ALL PRIVILEGES TO UserSite1;
```

**Site2:**
```sql
CREATE USER UserSite2 IDENTIFIED BY 2222;
GRANT ALL PRIVILEGES TO UserSite2;
```

**Cente:**
```sql
CREATE USER UserCenter IDENTIFIED BY 1212;
GRANT ALL PRIVILEGES TO UserCenter;
```
## Creating Database Links

In the Center machine, create database links to Site1 and Site2 databases:

```sql
CREATE PUBLIC DATABASE LINK lienSite1 
CONNECT TO UserSite1 IDENTIFIED BY '1111' 
USING 'Site1:1521/XE';
```

```sql
CREATE PUBLIC DATABASE LINK lienSite2 
CONNECT TO UserSite2 IDENTIFIED BY '2222' 
USING 'Site2:1521/XE';
```
u should create the other links betweeen sites based on the schema on the project overview 
Ensure the Oracle network files listener.ora and tnsnames.ora are properly configured on each machine for these links to function correctly.
#####here bruh ~~~~~~~~~~~~~~~~~~~~
## Central Database Creation

In the Center VM, create the central database schema consisting of the following tables:

```sql
CREATE TABLE Client(
    NoClient NUMBER PRIMARY KEY,
    NomClient VARCHAR2(50),
    PrénomClient VARCHAR2(50),
    VilleClient VARCHAR2(50),
    Age NUMBER
);

CREATE TABLE Agence(
    CodeAgence NUMBER PRIMARY KEY,
    NomAgence VARCHAR2(50),
    Adresse VARCHAR2(100),
    Ville VARCHAR2(50)
);

CREATE TABLE Compte(
    IdCompte NUMBER PRIMARY KEY,
    NCompte VARCHAR2(50),
    Solde NUMBER,
    NoClient NUMBER REFERENCES Client(NoClient),
    CodeAgence NUMBER REFERENCES Agence(CodeAgence)
);

```
Generate sample data for the central database using a data generator like generatedata.com. For instance:

- 300 agencies
- 1000 clients
- 5000 accounts
or u can just use the data in the repo folder (data)  
Centre VM :

![image](https://github.com/user-attachments/assets/122538d0-03be-4310-95a4-4e2e23f482d8)

## Database Fragmentation

Let the most frequently used selection queries in sites 1 and 2 be: implement the fragmented schemas from the central database at sites 1 and 2.

![image](https://github.com/user-attachments/assets/810440e7-6c0d-4dba-ab48-b2875b773d0a)

- Site1: BDDSite1.
- Site2: BDDSite2.
- Centre : BDDGlobale
  
**Site1 fragment:**
```sql
create table comptes1 as (select comptes.* from Center.clients@liencenter,center.comptes@liencenter 
where clients.idclient=comptes.idclient
and villeclient='casablanca' and solde<0);
create table clients1 as (select distinct clients.* from center.clients@liencenter,comptes1
where clients.idclient=comptes1.idclient);
```

**integrity constraints:**
```sql
alter table clients1 add constraint c1 primary key(idclient);
alter table comptes1 add constraint c2 primary key(idcompte)
alter table comptes1 add constraint f1 foreign key(idclient)
references clients1(idclient) on delete cascade;
```
![image](https://github.com/user-attachments/assets/cb282198-36ef-48a6-8def-a72e0f396ad3)


**Site2 fragment:**
```sql
create table comptes2 as (select comptes.* from Center.clients,center.comptes 
where clients.idclient=comptes.idclient
and villeclient='rabat' and solde>=0);
create table clients2 as (select distinct clients.* from center.clients,comptes2
where clients.idclient=comptes2.idclient);
```

**integrity constraints:**
```sql
eate table comptes2 as (select comptes.* from Center.clients,center.comptes 
where clients.idclient=comptes.idclient
and villeclient='rabat' and solde>=0);
create table clients2 as (select distinct clients.* from center.clients,comptes2
where clients.idclient=comptes2.idclient);
```
![image](https://github.com/user-attachments/assets/d6019459-2604-4af3-9015-5efa70c2003e)


  
## Synonyms and Fragment Duplication

Create public synonyms in Center to reference tables located at Site1 and Site2 without exposing the physical locations of the tables:

```sql
CREATE PUBLIC SYNONYM clients1 for clients1@LIENSITE1;
CREATE PUBLIC SYNONYM comptes1 for comptes1@LIENSITE1;
CREATE PUBLIC SYNONYM agences1 for agences1@LIENSITE1;

CREATE PUBLIC SYNONYM clients2 for clients2@LIENSITE2;
CREATE PUBLIC SYNONYM comptes2 for comptes2@LIENSITE2;
CREATE PUBLIC SYNONYM agences2 for agences2@LIENSITE2;

SELECT DISTINCT clients1.* from clients1;


```

## Fragment Duplication

Duplicate fragments from Site1 to Site2 to ensure data consistency and redundancy. in site 2 :

```sql
create table clients1 as (select * from clients1);
create table comptes1 as (select * from comptes1);
```

**integrity constraints:**
```sql
alter table clients1 add constraint c11 primary key (idclient);
alter table comptes1 add constraint c22 primary key (idcompte);
alter table comptes1 add constraint f11 foreign key (idclient)
references clients1(idclient) on delete cascade;

```

![image](https://github.com/user-attachments/assets/d5beef0e-bbf6-4f99-87d3-720e2576c15f)

## Triggers for Synchronization 
