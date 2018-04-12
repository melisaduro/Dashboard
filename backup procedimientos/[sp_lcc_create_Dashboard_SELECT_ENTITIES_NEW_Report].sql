USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_lcc_create_Dashboard_SELECT_ENTITIES_NEW_Report]    Script Date: 29/05/2017 14:11:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[sp_lcc_create_Dashboard_SELECT_ENTITIES_NEW_Report] (
	@scope as varchar(256),
	@table as varchar(256),
	@group as varchar(256),
	@Sheet as varchar(256),
	@tech as varchar(256),
	@nameSheet as varchar(256),
	@invalidate as bit,
	@report as varchar(256)
)
as
-------------------------------------------------------------------------------
-- Separar por Scopes 
if @scope ='MAIN HIGHWAYS REGION' set @group=1
else set @group=0

exec [dbo].[sp_lcc_create_Dashboard_Entities_NEW_Report] @scope,'[DASHBOARD]',@table,@group,@report

-- Modificación de la tabla lcc_entities_dashboard con la información relativa a la pestaña particular
exec dashboard.dbo.sp_lcc_dropifexists 'lcc_entities_dashboard_temp'
if @scope ='MAIN HIGHWAYS REGION' 
begin
	select e.*, '' as SHEET, '' as TECHNOLOGY, '' as CARRIER_AGGREGATION, '' as SMARTPHONE_MODEL, '' as FIRMWARE_VERSION
			,'' as HANDSET_CAPABILITY, '' as TEST_MODALITY, '' as MCC,'' as OPCOS
	into [DASHBOARD].[dbo].lcc_entities_dashboard_temp
	from [DASHBOARD].[dbo].lcc_entities_dashboard e
end
else
begin 
	select e.*, i.SHEET, i.TECHNOLOGY, i.CARRIER_AGGREGATION, i.SMARTPHONE_MODEL, i.FIRMWARE_VERSION
			,i.HANDSET_CAPABILITY,i.TEST_MODALITY,i.MCC,i.OPCOS
	into [DASHBOARD].[dbo].lcc_entities_dashboard_temp
	from [DASHBOARD].[dbo].lcc_entities_dashboard e,
		[DASHBOARD].[dbo].lcc_dashboard_info_data i
	where e.scope=i.scope and i.sheet=@nameSheet
end

if @invalidate = 1 
begin
	-------------------------------------------------------------------------------
	-- Modificación de las tablas para replicar la información de las medidas invalidadas. Se toma la inmediatamente anterior.
	exec [dbo].[sp_lcc_create_DashBoard_UPDATE_INVALID_MEASUR] @Sheet, @tech
end