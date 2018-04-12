declare @ciudad as varchar(256) = 'CORDOBA'
declare @pattern as varchar (256) = 'CORDOBA'
declare @Methodology as varchar (50) = 'D16'
declare @monthYearDash as varchar(100) = '2016_08'
declare @weekDash as varchar(50) = 'W30'
declare @camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round-[Database]-carrier-Report_Type-Entidad'
declare @operator as integer
declare @Report as varchar (256)='MUN'
declare @aggrType as varchar(256)='GRID'


use [FY1617_Coverage_Union]

begin
set @operator=1

--exec ('drop table lcc_warning_aggr_'+@pattern)
exec sp_lcc_create_tables_Coverage_Aggr_D16 
@ciudad, @operator, 0,'', 0, 1, @pattern, 'Y', @camposLlave, @monthYearDash, @weekDash,@Methodology,@Report,@aggrType
end

begin
set @operator=7

--exec ('drop table lcc_warning_aggr_'+@pattern)
exec sp_lcc_create_tables_Coverage_Aggr_D16 
@ciudad, @operator, 0,'', 0, 1, @pattern, 'Y', @camposLlave, @monthYearDash, @weekDash,@Methodology,@Report,@aggrType
end

begin
set @operator=3

--exec ('drop table lcc_warning_aggr_'+@pattern)
exec sp_lcc_create_tables_Coverage_Aggr_D16 
@ciudad, @operator, 0,'', 0, 1, @pattern, 'Y', @camposLlave, @monthYearDash, @weekDash,@Methodology,@Report,@aggrType
end

begin
set @operator=4

--exec ('drop table lcc_warning_aggr_'+@pattern)
exec sp_lcc_create_tables_Coverage_Aggr_D16 
@ciudad, @operator, 0,'', 0, 1, @pattern, 'Y', @camposLlave, @monthYearDash, @weekDash,@Methodology,@Report,@aggrType
end