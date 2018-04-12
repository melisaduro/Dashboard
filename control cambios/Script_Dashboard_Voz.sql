select *
from AGRIDS.dbo.lcc_dashboard_info_voice
where scope like '%railways%'



declare @la bit = 0
declare @RW_Road int = 4	
declare @RW_Railway int	= 3
declare @database as varchar(256)  ='[AGGRVoice4G]'
declare @UpdateMeasur as bit = 1
declare @report as varchar(256) = 'VDF'


exec [master].[dbo].[sp_lcc_create_DashBoard_MAIN_VOICE_NEW_Report] @la, @RW_Road, @RW_Railway, @database, @UpdateMeasur, @report


declare @namesheet as varchar(256) = 'C&T_4G_MAIN_CITIES M2M'
declare @typeMeasurI as varchar(256) = 'M2M'
declare @scope as varchar(256) = 'MAIN CITIES'
declare @UpdateMeasur as bit = 1
declare @report as varchar(256) = 'VDF'

exec [master].[dbo].[sp_lcc_create_DashBoard_VOICE_NEW_Report] @namesheet, @typeMeasurI, @scope, @UpdateMeasur, @report