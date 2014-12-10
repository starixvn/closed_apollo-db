 

INSERT INTO LogActionType (ActionTypeId,ActionTypeName)
VALUES (10, 'Transfer')

-------------------
INSERT INTO LogAction (
						ActionId,
						ActionTypeId,
						SPName,
						ActionName,
						ActionNameEN,
						ActionNameCT,
						ActionNameCS,
						ActionNameJP,
						ActionNameTH,
						ActionNameKO,
						ActionNameES,
						ActionNameVI,
						Items,
						SubItems,
						IsInternal)
VALUES					( 
						1000,
						10,
						'Age_Transfer_AgentToAgent',
						'Deposit/Draw to downline agent',
						'Deposit/Draw to downline agent',
						'Deposit/Draw to downline agent',
						'Deposit/Draw to downline agent',
						'Deposit/Draw to downline agent',
						'Deposit/Draw to downline agent',
						'Deposit/Draw to downline agent',
						'Deposit/Draw to downline agent',
						'Deposit/Draw to downline agent',
						'<root><xml path="r/z" /><row item="ParentId" alias="p" /><row item="ParentName" alias="pn" /><row item="ParentBalanceBefore" alias="pb" /><row item="TransType" alias="tp" /><row item="Amount" alias="m" /><row item="AgentId" alias="a" /><row item="Username" alias="an" /><row item="BalanceBefore" alias="ab" /></root>',
						NULL,
						0)

 
 
INSERT INTO LogAction (
						ActionId,
						ActionTypeId,
						SPName,
						ActionName,
						ActionNameEN,
						ActionNameCT,
						ActionNameCS,
						ActionNameJP,
						ActionNameTH,
						ActionNameKO,
						ActionNameES,
						ActionNameVI,
						Items,
						SubItems,
						IsInternal)
VALUES					( 
						1001,
						10,
						'Age_Transfer_AgentToCust',
						'Deposit/Draw to downline member',
						'Deposit/Draw to downline member',
						'Deposit/Draw to downline member',
						'Deposit/Draw to downline member',
						'Deposit/Draw to downline member',
						'Deposit/Draw to downline member',
						'Deposit/Draw to downline member',
						'Deposit/Draw to downline member',
						'Deposit/Draw to downline member',
						'<root><xml path="r/z" /><row item="ParentId" alias="p" /><row item="ParentName" alias="pn" /><row item="ParentBalanceBefore" alias="pb" /><row item="TransType" alias="tp" /><row item="Amount" alias="m" /><row item="CustId" alias="c" /><row item="Username" alias="cn" /><row item="BalanceBefore" alias="cb" /></root>',
						NULL,
						0)
