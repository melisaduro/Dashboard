use AddedValue 

declare @monthYear as nvarchar(50) = '201711'        --MES Y A�O DE ACTUALIZACI�N
declare @ReportWeek as nvarchar(50) = 'W46'          --SEMANA DE ACTUALIZACI�N
declare @last_measurement as varchar(256) = 'last_measurement_osp'
declare @id as varchar(50)='OSP'

exec plcc_Data_Qlik_Dashboard_Williams @monthYear,@ReportWeek,@last_measurement,@id

exec plcc_Voice_Qlik_Dashboard_Williams @monthYear,@ReportWeek,@last_measurement,@id