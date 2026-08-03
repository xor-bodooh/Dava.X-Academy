USE TimesheetDB;
GO

-- Insert some dummy work hours for our existing timesheet (TimesheetID = 1)
INSERT INTO TimesheetEntries
(TimesheetID, ProjectID, CategoryID, LocationID, WorkDate, HoursWorked, WorkDescription, AdditionalInfo)
VALUES
    (1, 1, 1, 1, '2025-05-05', 8.00, 'Initial setup', '{"device":"Laptop","workMode":"Office"}'),
    (1, 1, 1, 2, '2025-05-08', 6.50, 'Backend development', '{"device":"Laptop","workMode":"Remote"}');
GO

USE TimesheetDB;
GO

INSERT INTO TimesheetEntries
(TimesheetID, ProjectID, CategoryID, LocationID, WorkDate, HoursWorked, WorkDescription, AdditionalInfo)
VALUES
    -- Scenario A: Complete JSON with all the keys we are looking for
    (1, 1, 1, 1, '2025-05-09', 4.0, 'Office Work',
     '{"device": "Laptop", "browser": "Edge", "workMode": "Office"}'),

    -- Scenario B: Different values, same keys
    (1, 1, 1, 2, '2025-05-10', 5.0, 'Remote Work',
     '{"device": "Desktop PC", "browser": "Chrome", "workMode": "Remote"}'),

    -- Scenario C: Missing the "device" key (to see what happens)
    (1, 1, 1, 1, '2025-05-11', 2.0, 'Quick Mobile Fix',
     '{"browser": "Safari", "workMode": "Commute"}'),

    -- Scenario D: Valid JSON, but completely unrelated keys!
    (1, 1, 1, 1, '2025-05-12', 1.0, 'Client Meeting',
     '{"meetingApp": "Zoom", "cameraOn": true}');
GO