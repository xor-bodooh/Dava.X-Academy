/* ============================================================================
   DATABASE ARCHITECTURE: TIMESHEET SYSTEM
   PLATFORM: MS SQL SERVER
   ============================================================================ */

USE master;
GO

IF DB_ID('TimesheetDB') IS NOT NULL
    BEGIN
        ALTER DATABASE TimesheetDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE TimesheetDB;
    END;
GO

CREATE DATABASE TimesheetDB;
GO

USE TimesheetDB;
GO

-- INDEPENDENT TABLES
CREATE TABLE Departments (
                             DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
                             DepartmentName NVARCHAR(100) NOT NULL,
                             ManagerName NVARCHAR(100) NOT NULL,
                             IsActive BIT NOT NULL CONSTRAINT DF_Departments_IsActive DEFAULT(1),
                             CONSTRAINT UQ_Department_Name UNIQUE(DepartmentName),
                             CONSTRAINT CK_Department_Name CHECK(LEN(DepartmentName) >= 3)
);
GO

CREATE TABLE Clients (
                         ClientID INT IDENTITY(1,1) PRIMARY KEY,
                         ClientName NVARCHAR(150) NOT NULL,
                         IsActive BIT NOT NULL CONSTRAINT DF_Clients_IsActive DEFAULT(1),
                         CONSTRAINT UQ_Client_Name UNIQUE(ClientName)
);
GO

CREATE TABLE TaskCategories (
                                CategoryID INT IDENTITY(1,1) PRIMARY KEY,
                                CategoryName NVARCHAR(100) NOT NULL,
                                Billable BIT NOT NULL,
                                CONSTRAINT UQ_Category_Name UNIQUE(CategoryName)
);
GO

CREATE TABLE WorkLocations (
                               LocationID INT IDENTITY(1,1) PRIMARY KEY,
                               LocationName NVARCHAR(100) NOT NULL,
                               IsRemote BIT NOT NULL
);
GO

-- DEPENDENT TABLES
CREATE TABLE Employees (
                           EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
                           FirstName NVARCHAR(100) NOT NULL,
                           LastName NVARCHAR(100) NOT NULL,
                           Email NVARCHAR(150) NOT NULL,
                           HireDate DATE NOT NULL,
                           Salary DECIMAL(10,2) NOT NULL,
                           DepartmentID INT NOT NULL,
                           JobTitle NVARCHAR(100) NOT NULL CONSTRAINT DF_Employees_JobTitle DEFAULT('Software Developer'),
                           IsActive BIT NOT NULL CONSTRAINT DF_Employees_IsActive DEFAULT(1),
                           CONSTRAINT UQ_Employees_Email UNIQUE(Email),
                           CONSTRAINT CK_Employees_Salary CHECK(Salary > 0),
                           CONSTRAINT FK_Employees_Departments FOREIGN KEY(DepartmentID) REFERENCES Departments(DepartmentID)
);
GO

CREATE TABLE Projects (
                          ProjectID INT IDENTITY(1,1) PRIMARY KEY,
                          ProjectName NVARCHAR(150) NOT NULL,
                          ClientID INT NOT NULL,
                          StartDate DATE NOT NULL,
                          EndDate DATE NULL,
                          Budget DECIMAL(12,2) NOT NULL,
                          Status NVARCHAR(30) NOT NULL CONSTRAINT DF_Project_Status DEFAULT('Active'),
                          CONSTRAINT CK_Project_Budget CHECK(Budget > 0),
                          CONSTRAINT CK_Project_Dates CHECK(EndDate IS NULL OR EndDate >= StartDate),
                          CONSTRAINT FK_Project_Client FOREIGN KEY(ClientID) REFERENCES Clients(ClientID)
);
GO

CREATE TABLE LeaveRequests (
                               LeaveID INT IDENTITY(1,1) PRIMARY KEY,
                               EmployeeID INT NOT NULL,
                               StartDate DATE NOT NULL,
                               EndDate DATE NOT NULL,
                               LeaveType NVARCHAR(50) NOT NULL,
                               Status NVARCHAR(30) NOT NULL CONSTRAINT DF_Leave_Status DEFAULT('Pending'),
                               CONSTRAINT CK_Leave_Dates CHECK(EndDate >= StartDate),
                               CONSTRAINT FK_Leave_Employee FOREIGN KEY(EmployeeID) REFERENCES Employees(EmployeeID)
);
GO

CREATE TABLE Timesheets (
                            TimesheetID INT IDENTITY(1,1) PRIMARY KEY,
                            EmployeeID INT NOT NULL,
                            WeekStart DATE NOT NULL,
                            WeekEnd DATE NOT NULL,
                            Status NVARCHAR(30) NOT NULL CONSTRAINT DF_Timesheet_Status DEFAULT('Draft'),
                            SubmittedDate DATETIME2 NULL,
                            ApprovedDate DATETIME2 NULL,
                            CONSTRAINT CK_Timesheet_Dates CHECK(WeekEnd >= WeekStart),
                            CONSTRAINT FK_Timesheet_Employee FOREIGN KEY(EmployeeID) REFERENCES Employees(EmployeeID)
);
GO


CREATE TABLE TimesheetEntries (
                                  EntryID INT IDENTITY(1,1) PRIMARY KEY,
                                  TimesheetID INT NOT NULL,
                                  ProjectID INT NOT NULL,
                                  CategoryID INT NOT NULL,
                                  LocationID INT NOT NULL,
                                  WorkDate DATE NOT NULL,
                                  HoursWorked DECIMAL(4,2) NOT NULL,
                                  WorkDescription NVARCHAR(500) NULL,
                                  AdditionalInfo NVARCHAR(MAX) NULL, -- JSON COLUMN
                                  CONSTRAINT CK_TimesheetEntry_Hours CHECK(HoursWorked > 0 AND HoursWorked <= 24),
                                  CONSTRAINT CK_TimesheetEntry_JSON CHECK(AdditionalInfo IS NULL OR ISJSON(AdditionalInfo)=1),
                                  CONSTRAINT FK_Entry_Timesheet FOREIGN KEY(TimesheetID) REFERENCES Timesheets(TimesheetID),
                                  CONSTRAINT FK_Entry_Project FOREIGN KEY(ProjectID) REFERENCES Projects(ProjectID),
                                  CONSTRAINT FK_Entry_Category FOREIGN KEY(CategoryID) REFERENCES TaskCategories(CategoryID),
                                  CONSTRAINT FK_Entry_Location FOREIGN KEY(LocationID) REFERENCES WorkLocations(LocationID)
);
GO

-- DATA

INSERT INTO Departments (DepartmentName, ManagerName) VALUES ('Software Development', 'Andrei Popescu');
INSERT INTO Clients (ClientName) VALUES ('Microsoft'), ('Internal Operations');
INSERT INTO TaskCategories (CategoryName, Billable) VALUES ('Development', 1), ('Vacation', 0);
INSERT INTO WorkLocations (LocationName, IsRemote) VALUES ('Bucharest Office', 0), ('Remote', 1);
INSERT INTO Employees (FirstName, LastName, Email, HireDate, Salary, DepartmentID)
VALUES ('Adriana', 'Laurentiu', 'adriana@email.com', '2023-01-15', 6500, 1),
       ('Andrei', 'Popescu', 'andrei@email.com', '2020-05-11', 9800, 1);
INSERT INTO Projects (ProjectName, ClientID, StartDate, Budget)
VALUES ('Payroll System', 1, '2024-01-01', 180000), ('Internal PTO', 2, '2024-01-01', 999999);
INSERT INTO Timesheets (EmployeeID, WeekStart, WeekEnd, Status)
VALUES (1, '2025-05-05', '2025-05-11', 'Draft');
INSERT INTO LeaveRequests (EmployeeID, StartDate, EndDate, LeaveType, Status)
VALUES (1, '2025-05-06', '2025-05-07', 'Annual Leave', 'Approved');
GO

-- INDEx
CREATE INDEX IX_Employees_LastName ON Employees(LastName);
CREATE INDEX IX_Projects_Status ON Projects(Status);
CREATE INDEX IX_TimesheetEntries_WorkDate ON TimesheetEntries(WorkDate);
GO

--TRIGGER
CREATE TRIGGER trg_AutoCompleteVacationHours
    ON TimesheetEntries
    AFTER INSERT, UPDATE
    AS
BEGIN
    SET NOCOUNT ON;


    DECLARE @VacationCategoryID INT = (SELECT CategoryID FROM TaskCategories WHERE CategoryName = 'Vacation');
    DECLARE @PTOProjectID INT = (SELECT ProjectID FROM Projects WHERE ProjectName = 'Internal PTO');


    UPDATE te
    SET te.CategoryID = @VacationCategoryID,
        te.ProjectID = @PTOProjectID,
        te.WorkDescription = 'AUTO-COMPLETED: Employee on approved vacation.'
    FROM TimesheetEntries te
             INNER JOIN inserted i ON te.EntryID = i.EntryID
             INNER JOIN Timesheets t ON te.TimesheetID = t.TimesheetID
             INNER JOIN LeaveRequests lr ON t.EmployeeID = lr.EmployeeID
    WHERE lr.Status = 'Approved'
      AND i.WorkDate BETWEEN lr.StartDate AND lr.EndDate;
END;
GO

CREATE PROCEDURE usp_ReviewTimesheet
(
    @TimesheetID INT,
    @Action NVARCHAR(20) -- 'Approve' or 'Reject'
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Action = 'Approve'
        BEGIN
            UPDATE Timesheets SET Status = 'Approved', ApprovedDate = SYSDATETIME()
            WHERE TimesheetID = @TimesheetID AND Status = 'Submitted';
        END
    ELSE IF @Action = 'Reject'
        BEGIN
            UPDATE Timesheets SET Status = 'Rejected', ApprovedDate = NULL
            WHERE TimesheetID = @TimesheetID AND Status = 'Submitted';
        END
END;
GO

--VIEW
CREATE VIEW dbo.vw_EmployeeProjectHours
AS
SELECT
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS FullName,
    p.ProjectName,
    SUM(te.HoursWorked) AS TotalHours
FROM Employees e
         INNER JOIN Timesheets t ON e.EmployeeID = t.EmployeeID
         INNER JOIN TimesheetEntries te ON t.TimesheetID = te.TimesheetID
         INNER JOIN Projects p ON te.ProjectID = p.ProjectID
GROUP BY e.EmployeeID, e.FirstName, e.LastName, p.ProjectName;
GO

--MATERIALIZED VIEW
CREATE VIEW dbo.vw_ProjectSummary
            WITH SCHEMABINDING
AS
SELECT
    p.ProjectID,
    COUNT_BIG(*) AS TotalEntries,
    SUM(ISNULL(te.HoursWorked, 0)) AS TotalHours
FROM dbo.Projects p
         INNER JOIN dbo.TimesheetEntries te ON p.ProjectID = te.ProjectID
GROUP BY p.ProjectID;
GO

-- Create the physical index on disk to materialize the view
CREATE UNIQUE CLUSTERED INDEX IX_vw_ProjectSummary
    ON dbo.vw_ProjectSummary(ProjectID);
GO


-- 1. SELECT query using GROUP BY
-- This query calculates the total number of billable vs non-billable hours logged across the system.
SELECT
    tc.Billable,
    SUM(te.HoursWorked) AS TotalHours
FROM TimesheetEntries te
         INNER JOIN TaskCategories tc ON te.CategoryID = tc.CategoryID
GROUP BY tc.Billable;
GO

-- 2. SELECT query using LEFT JOIN
-- This query retrieves all employees and pairs them with their timesheets.
-- The LEFT JOIN ensures we see employees even if they haven't submitted a timesheet yet (TimesheetID will be NULL).
SELECT
    e.FirstName,
    e.LastName,
    t.TimesheetID,
    t.Status
FROM Employees e
         LEFT JOIN Timesheets t ON e.EmployeeID = t.EmployeeID
ORDER BY e.LastName;
GO

-- 3. SELECT query using an Analytic/Window Function (DENSE_RANK)
-- This query ranks employees based on their salary within their specific department.
-- DENSE_RANK ensures there are no gaps in ranking numbers if two employees have the exact same salary.
SELECT
    DepartmentID,
    FirstName,
    LastName,
    Salary,
    DENSE_RANK() OVER (PARTITION BY DepartmentID ORDER BY Salary DESC) AS DepartmentSalaryRank
FROM Employees;
GO

-- 4. Demonstration of Semi-Structured JSON Data Extraction
-- This query extracts specific properties from the JSON string stored in the AdditionalInfo column.
SELECT
    EntryID,
    WorkDescription,
    JSON_VALUE(AdditionalInfo,'$.device') AS DeviceUsed,
    JSON_VALUE(AdditionalInfo,'$.workMode') AS WorkMode
FROM TimesheetEntries
WHERE AdditionalInfo IS NOT NULL;
GO