

--Select * from [dbo].[Function]

--Select * from [dbo].[FunctionGroup]

-------
SET IDENTITY_INSERT [FunctionGroup]  ON
INSERT INTO [FunctionGroup] (
FunctionGroupId,
GroupKey,
GroupName,
DisplayOrder,
IsActive
)
VALUES (
6,
'Credit_Balance',
'Credit/Balance',
2,
1
)

SET IDENTITY_INSERT [FunctionGroup] OFF
---

UPDATE [FunctionGroup]
SET DisplayOrder = 3
WHERE FunctionGroupId= 4

UPDATE [FunctionGroup]
SET DisplayOrder = 4
WHERE FunctionGroupId= 1


UPDATE [FunctionGroup]
SET DisplayOrder = 5
WHERE FunctionGroupId= 3

-----------------


SET IDENTITY_INSERT [Function]  ON
INSERT INTO [Function] (
FunctionID,
FunctionGroupId,
FunctionName,
FunctionKey,
Description,
CRUD,
DisplayOrder,
IsActive) 
VALUES(
22,
5,
'Deposit/Draw',
'DepositDraw',
'Deposit/Draw',
1,
1,
1
)

---------------

INSERT INTO [Function] (
FunctionID,
FunctionGroupId,
FunctionName,
FunctionKey,
Description,
CRUD,
DisplayOrder,
IsActive) 
VALUES(
23,
3,
'Credit Report',
'CreditReport',
'Credit Report',
0,
14,
1
)

SET IDENTITY_INSERT [Function] OFF

------

UPDATE [Function] SET DisplayOrder = 15 WHERE FunctionID = 14


--------------------------------------
