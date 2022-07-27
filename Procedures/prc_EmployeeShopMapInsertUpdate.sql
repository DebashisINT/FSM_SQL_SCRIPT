IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[prc_EmployeeShopMapInsertUpdate]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [prc_EmployeeShopMapInsertUpdate] AS' 
END
GO

ALTER PROCEDURE [dbo].[prc_EmployeeShopMapInsertUpdate]
(
@ACTION NVARCHAR(500)=NULL,
@userid int=null,
@SHOP_CODEList udt_ShopCodeList readonly,
@User_IdList udt_UserIdList readonly, 
@PARTY_TYPE INT=NULL,
-- Rev 1.0
--@SHOP_CODE nvarchar(100)=null,
@SHOP_CODE nvarchar(max)=null,
-- End of Rev 1.0

@Users nvarchar(max)=null,
@headerid BIGINT=null,
@NAME nvarchar(100)=null,
-- Rev 1.0
@BRANCHID int=0
-- End of Rev 1.0
)
 AS
 /***************************************************************************************************************************************
1.0		05/10/2021		Sanchita	v2.0.26		Mantis issue 24362 and 24363
2.0		28/07/2022		Sanchita	v2.0.31		When Assign Party is done and same name is given from "Select Party & Map Users" window, 
												then the record already present with that name in table FTS_EmployeeShopMapHeader will be updated.
												No new record to be added. 
***************************************************************************************************************************************/
Begin
	DECLARE @sqlStrTable NVARCHAR(MAX)
	IF @ACTION='INSERT'
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION

		CREATE TABLE #EMPSHOP
		(
		USER_ID BIGINT,
		SHOP_CODE VARCHAR(100)
		)

		INSERT INTO #EMPSHOP
		SELECT m.user_id,w.Shop_Code
		FROM @SHOP_CODEList w, @User_IdList m

		IF NOT EXISTS (SELECT * FROM #EMPSHOP w INNER JOIN FTS_EmployeeShopMap MAP ON w.USER_ID=MAP.USER_ID AND w.SHOP_CODE=MAP.SHOP_CODE )
		BEGIN		

			--IF EXISTS(SELECT 1 FROM FTS_EmployeeShopMap WHERE ASSIGN_BY=@userid AND SHOP_TYPE=@PARTY_TYPE)
			--BEGIN
			--	DELETE FROM FTS_EmployeeShopMap WHERE SHOP_TYPE=@PARTY_TYPE --ASSIGN_BY=@userid AND
			--END

			-- Rev 1.0
			--INSERT INTO FTS_EmployeeShopMap
			--SELECT USR.user_id,USR.user_contactId,@PARTY_TYPE,w.Shop_Code,
			--GETDATE(),@userid,0
			--FROM @SHOP_CODEList w, @User_IdList m
			--INNER JOIN tbl_master_user USR ON USR.user_id=m.User_id
			INSERT INTO FTS_EmployeeShopMap
			SELECT USR.user_id,USR.user_contactId,@PARTY_TYPE,w.Shop_Code,
			GETDATE(),@userid,0,0
			FROM @SHOP_CODEList w, @User_IdList m
			INNER JOIN tbl_master_user USR ON USR.user_id=m.User_id
			-- End of Rev 1.0


			SELECT USR.user_id,USR.user_contactId,@PARTY_TYPE,w.Shop_Code,
			GETDATE(),@userid
			FROM @SHOP_CODEList w, @User_IdList m
			INNER JOIN tbl_master_user USR ON USR.user_id=m.User_id
		END
		
		COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION
		END CATCH
	END

	IF @ACTION='UnAssign'
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION
			
			DELETE FROM FTS_EmployeeShopMap WHERE ID IN (SELECT Shop_Code FROM @SHOP_CODEList)
			
		COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION
		END CATCH
	END

	IF @ACTION='AssignShopUserNew'
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION
			
		IF OBJECT_ID('tempdb..#UserList') IS NOT NULL
			DROP TABLE #UserList
		CREATE TABLE #UserList
		(
			USER_ID BIGINT,
			Internal_id VARCHAR(100)
		)

		set @Users = REPLACE(''''+@Users+'''',',',''',''')

		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #UserList select user_id,user_contactId from tbl_master_user where user_id in ('+@Users+')'
		EXEC SP_EXECUTESQL @sqlStrTable

		-- Rev 1.0
		IF OBJECT_ID('tempdb..#PartyList') IS NOT NULL
			DROP TABLE #PartyList

		CREATE TABLE #PartyList
		(
			shop_code VARCHAR(100),
			shop_name VARCHAR(5000)
		)

		set @SHOP_CODE = REPLACE(''''+@SHOP_CODE+'''',',',''',''')

		SET @sqlStrTable=''
		SET @sqlStrTable=' INSERT INTO #PartyList select Shop_Code,Shop_Name from tbl_Master_shop where Shop_Code in ('+@SHOP_CODE+')'
		EXEC SP_EXECUTESQL @sqlStrTable

		DECLARE @ShopCode VARCHAR(100), @ShopName VARCHAR(5000)
		-- End of Rev 1.0

		IF EXISTS(SELECT * FROM FTS_EmployeeShopMapHeader WHERE ID=@headerid)
			BEGIN
				delete from FTS_EmployeeShopMap where Header_id=@headerid
				update FTS_EmployeeShopMapHeader set UPDATED_BY=@userid,UPDATED_ON=GETDATE() where id=@headerid

				-- Rev 1.0
				--INSERT INTO FTS_EmployeeShopMap
				--SELECT USER_ID,Internal_id,@PARTY_TYPE,@SHOP_CODE,GETDATE(),@userid,@headerid
				--FROM #UserList

				DECLARE db_cursorPartyList CURSOR FOR  
				Select Shop_Code,Shop_Name from #PartyList

				OPEN db_cursorPartyList   
				FETCH NEXT FROM db_cursorPartyList INTO @ShopCode,@ShopName
				WHILE @@FETCH_STATUS = 0   
				BEGIN

					INSERT INTO FTS_EmployeeShopMap
					SELECT USER_ID,Internal_id,@PARTY_TYPE,@ShopCode,GETDATE(),@userid,@headerid,@BRANCHID
					FROM #UserList

				FETCH NEXT FROM db_cursorPartyList INTO @ShopCode,@ShopName
				end
				CLOSE db_cursorPartyList   
				DEALLOCATE db_cursorPartyList

				
				-- End of Rev 1.0

				SELECT * from #UserList
			END
			ELSE
			BEGIN
				IF NOT EXISTS (SELECT * FROM #UserList w INNER JOIN FTS_EmployeeShopMap MAP ON w.USER_ID=MAP.USER_ID AND MAP.SHOP_CODE=@SHOP_CODE and map.Header_id=@headerid)
				BEGIN
					-- Rev 2.0
					if(@headerid = 0 or @headerid is null)
						set @headerid = (select top 1 ID from FTS_EmployeeShopMapHeader where name=@NAME)
					
					IF @headerid = 0 OR @headerid is null
					begin
					-- End of Rev 2.0

						INSERT INTO FTS_EmployeeShopMapHeader (NAME,CREATED_ON,CREATED_BY)
						VALUES(@NAME,GETDATE(),@userid)

						SET @headerid=SCOPE_IDENTITY();
					-- Rev 2.0
					END
					-- End of Rev 2.0

					-- Rev 1.0
					--INSERT INTO FTS_EmployeeShopMap
					--SELECT USER_ID,Internal_id,@PARTY_TYPE,@SHOP_CODE,GETDATE(),@userid,@headerid
					--FROM #UserList

					
					DECLARE db_cursorPartyList CURSOR FOR  
					Select Shop_Code,Shop_Name from #PartyList

					OPEN db_cursorPartyList   
					FETCH NEXT FROM db_cursorPartyList INTO @ShopCode,@ShopName
					WHILE @@FETCH_STATUS = 0   
					BEGIN

						INSERT INTO FTS_EmployeeShopMap
						SELECT USER_ID,Internal_id,@PARTY_TYPE,@ShopCode,GETDATE(),@userid,@headerid,@BRANCHID
						FROM #UserList

					FETCH NEXT FROM db_cursorPartyList INTO @ShopCode,@ShopName
					end
					CLOSE db_cursorPartyList   
					DEALLOCATE db_cursorPartyList

					
					-- End of Rev 1.0

					SELECT * from #UserList
				END			
			END

		DROP TABLE #PartyList
		
		-- End of Rev 1.0
		
			
		DROP TABLE #UserList

		COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION
		END CATCH
	END

	IF @ACTION='DeleteShopUserNew'
	BEGIN
		BEGIN TRY
		BEGIN TRANSACTION
			
			DELETE FROM FTS_EmployeeShopMap WHERE Header_id=@headerid
			delete from FTS_EmployeeShopMapHeader where id=@headerid
		COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION
		END CATCH
	END
END