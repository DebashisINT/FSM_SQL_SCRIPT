IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PROC_Common_Report_Header]') AND type in (N'P', N'PC')) 
 BEGIN 
	 EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [PROC_Common_Report_Header] AS'  
 END 
 GO 
GO

ALTER PROCEDURE [dbo].[PROC_Common_Report_Header]
@Comp_ID VARCHAR(10),
@FINYEAR VARCHAR(10)

AS
/*********************************************************************************************************
Rev 1.0		Sanchita    09-08-2023      V2.0.42     FSM Portal - Enhance the Export to excel in Employee Master. Mantis : 26708
*********************************************************************************************************/
	BEGIN

		SELECT cmp_Name AS Col_Comp_Name, cmp_panNo AS Col_Comp_PAN, cmp_CIN AS Col_Comp_CIN, 
			   CASE WHEN ISNULL(add_address1,'') + ISNULL(add_address2,'') + ISNULL(add_address3,'') <> '' 
					THEN CASE WHEN ISNULL(add_address1,'') <> '' THEN ISNULL(add_address1,'') + ', ' ELSE '' END +
						 CASE WHEN ISNULL(add_address2,'') <> '' THEN ISNULL(add_address2,'') + ', ' ELSE '' END +
						 CASE WHEN ISNULL(add_address3,'') <> '' THEN ISNULL(add_address3,'') + ', ' ELSE '' END + 
						 CASE WHEN ISNULL(add_landMark,'') <> '' THEN ISNULL(add_landMark,'') + ', ' ELSE '' END +  
						 CASE WHEN ISNULL(city_name,'')    <> '' THEN ISNULL(city_name,'')    + ' '  ELSE '' END + 
						 CASE WHEN ISNULL(pin_code,'')     <> '' THEN '- '+ISNULL(pin_code,'')+ ', ' ELSE '' END + 
						 CASE WHEN ISNULL(state,'')        <> '' THEN ISNULL(state,'')        + ', ' ELSE '' END + 
						 CASE WHEN ISNULL(cou_country,'')  <> '' THEN ISNULL(cou_country,'')  + ' '  ELSE '' END
					ELSE '' END AS Col_Comp_Add,
			   CASE WHEN ISNULL(phf_phoneNumber,'') <> '' THEN 'Ph: '  + ISNULL(phf_phoneNumber,'') ELSE '' END AS Col_Comp_PhNo, 
			   CASE WHEN ISNULL(phf_faxNumber,'')   <> '' THEN 'Fax: ' + ISNULL(phf_faxNumber,'')   ELSE '' END AS Col_Comp_FaxNo,
			   (
				SELECT 'Accounting Period: ' + CONVERT(VARCHAR(10), FinYear_StartDate, 105) + ' To ' + CONVERT(VARCHAR(10), FinYear_EndDate, 105) From Master_FinYear Where FinYear_Code = @FINYEAR
			   ) AS Col_AC_Period
		  FROM tbl_master_company CMP
			  -- Rev 1.0
			   --INNER JOIN tbl_master_address CMPADD ON CMP.cmp_internalid = CMPADD.add_cntId
			   --INNER JOIN tbl_master_state ST ON CMPADD.add_state = ST.id
			   --INNER JOIN tbl_master_city CT ON CMPADD.add_city = CT.city_id
			   --INNER JOIN tbl_master_pinzip PZ ON CMPADD.add_pin = PZ.pin_id
			   --INNER JOIN tbl_master_country CO ON CMPADD.add_country = CO.cou_id
			   --INNER JOIN tbl_master_phonefax PF ON CMP.cmp_internalid = PF.phf_cntId
			  -- WHERE add_entity = 'Company'
		   --AND cmp_internalid = @Comp_ID
			   LEFT OUTER JOIN tbl_master_address CMPADD ON CMP.cmp_internalid = CMPADD.add_cntId AND add_entity = 'Company'
			   LEFT OUTER JOIN tbl_master_state ST ON CMPADD.add_state = ST.id
			   LEFT OUTER JOIN tbl_master_city CT ON CMPADD.add_city = CT.city_id
			   LEFT OUTER JOIN tbl_master_pinzip PZ ON CMPADD.add_pin = PZ.pin_id
			   LEFT OUTER JOIN tbl_master_country CO ON CMPADD.add_country = CO.cou_id
			   LEFT OUTER JOIN tbl_master_phonefax PF ON CMP.cmp_internalid = PF.phf_cntId
		 WHERE cmp_internalid = @Comp_ID
		-- End of Rev 1.0
	END
GO