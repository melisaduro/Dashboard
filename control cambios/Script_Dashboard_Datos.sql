select *
from AGRIDS.dbo.lcc_dashboard_info_data

declare @la bit = 0
declare @RW_Road int = 4	
declare @RW_Railway int	= 3
declare @database as varchar(256)  ='[AGGRDATA3G]'
declare @UpdateMeasur as bit = 1
declare @Methodology as varchar(50) ='D16'
declare @report as varchar(256) = 'MUN'


exec [master].[dbo].[sp_lcc_create_DashBoard_MAIN_DATA_NEW_Report] @la, @RW_Road, @RW_Railway, @database, @UpdateMeasur, @Methodology, @report


declare @namesheet as varchar(255)='C&T_4G_CAONLY_SMALLER_CITIES'
declare @scope as varchar(256)='SMALLER CITIES'
declare @LA as bit=0
declare @UpdateMeasur as bit=1
declare @Methodology as varchar(50)='D16'
declare @report as varchar(256)='VDF'

exec [master].[dbo].[sp_lcc_create_DashBoard_DATA_NEW_Report] @namesheet, @scope, @LA, @UpdateMeasur, @Methodology, @report