CREATE TABLE employees (
    employee_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    salary NUMBER,
    commission_pct NUMBER
);

INSERT INTO employees VALUES (101, 'Alice', 'Engineer', 10000, 0.15);
INSERT INTO employees VALUES (102, 'Bob', 'Analyst', 8000, NULL);
COMMIT;
