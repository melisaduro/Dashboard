USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Coverage_Dashboard]    Script Date: 25/05/2017 10:29:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_MDD_Coverage_Dashboard] 
(  
	@dashMonthYear nvarchar(50),
	@dashWeek nvarchar(50)
)
as

declare @tech nvarchar(500),			
		@report_date nvarchar(500),	
		@scope  nvarchar(500),		
		@cmd nvarchar(1500),			
		@wild_filter nvarchar(256),  
		@la bit,						
		@idx integer,
		@sub_idx integer,
		@sub_idx_max integer,
		@band nvarchar(50)

----Prueba----
set @Scope = 'Main'
set @la = 1
set @dashWeek = 'W20'
set  @dashMonthYear = '2016_05'
--------------

-------Tabla con frecuencias-------
-----------------------------------
exec master.dbo.sp_lcc_dropifexists '#band_table'

select sq.*,
ROW_NUMBER() OVER(partition by sq.[total band] order by sq.[total band]) as idx
into #band_table 
from
(select distinct Band,
CASE WHEN band like '%UMTS%' then '3G'
     WHEN band like '%LTE%' then '4G'
END AS [total band]
from [AGRIDS].[dbo].[lcc_ref_servingOperator_Freq] where  band like 'LTE%' or band like 'UMTS%') sq

-------------Filtro de entornos-----
------------------------------------
set @idx=0
if @Scope = 'Main'
begin
	if @la = 1
	begin
		set @wild_filter = '%8G%'
	end
	else
	begin
		set @wild_filter = '8G'
	end 		
end

--------------Filtrado temporal--------------
---------------------------------------------
while @idx < 3
begin
	if @idx = 0 set @tech='2G'
	if @idx = 1 set @tech='3G'
	if @idx = 2 set @tech='4G'
	
	set @cmd = 'exec sp_lcc_dropifexists ''filter_cober_'+@tech+'''
				select *
				into filter_cober_'+@tech+'  
				from
					(select 
						*, 
						DENSE_RANK() OVER (partition by entidad order by monthYearDash desc,WeekDash desc) as rank_idx
					from 
						[AGGRCoverage].[dbo].[lcc_aggr_sp_MDD_Coverage_'+@tech+'] 
					where monthYearDash <= '''+@dashMonthYear+''' 
					and weekDash <= '''+@dashWeek+''') sq
				where sq.rank_idx = 1'

	execute(@cmd)

set @idx = @idx+1
end 
---------------------------------------------
---------------------------------------------
set @idx=0

while @idx < 3
begin
	
	IF @idx = 0
	begin
		set @tech='2G'
		set @cmd = 'exec sp_lcc_dropifexists ''cober_2G_Total''
					select
						cob.entidad
						,cob.mnc
						,CONVERT(DECIMAL(5,1),ROUND(100.0*SUM(ISNULL([<=-70 a <-67],0)+ISNULL([<=-67 a <-66],0)+ISNULL([<=-66 a <-65],0)+ISNULL([<=-65 a <-62],0)+ISNULL([<=-62 a <-60],0)+ISNULL([>=-60],0))/SUM(cob.muestras),2)) as [cobertura 2G %]
						into cober_2G_Total 
					from 
						filter_cober_'+@tech+' cob,
						[AGRIDS].[dbo].[lcc_parcelas] parcels	 
					where 
						[Database] like ''%'+@scope+'%'' 
						and cob.parcel = parcels.Nombre
						and parcels.entorno like '''+@wild_filter+'''
						group by cob.entidad,cob.mnc'
		execute(@cmd)
	end

	IF @idx = 1
	begin 
		set @tech='3G'
		set @sub_idx = 1
		set @sub_idx_max = (select MAX(idx) from #band_table where [total band] = @tech)

		set @cmd = 'exec sp_lcc_dropifexists ''cober_3G_Total''
					select
						cob.entidad
						,cob.mnc
						,CONVERT(DECIMAL(5,1),ROUND(100.0*SUM(ISNULL([<=-80 a <-77],0)+ISNULL([<=-77 a <-75],0)+ISNULL([<=-75 a <-72],0)+ISNULL([<=-72 a <-70],0)+ISNULL([<=-70 a <-67],0)+ISNULL([<=-67 a <-66],0)+ISNULL([<=-66 a <-65],0)+ ISNULL([<=-65 a <-62],0)+ ISNULL([<=-62 a <-60],0)+ ISNULL([>=-60],0))/SUM(cob.muestras),2)) as [Cobertura 3G %]
						,SUM(cob.muestras) as max_registers
						into cober_3G
					from
						filter_cober_'+@tech+' cob,
						[AGRIDS].[dbo].[lcc_parcelas] parcels	 
					where 
						[Database] like ''%'+@scope+'%'' 
						and cob.parcel = parcels.Nombre
						and parcels.entorno like '''+@wild_filter+'''
						and band is NULL
						group by cob.entidad,cob.mnc'
		execute(@cmd)

		while @sub_idx <= @sub_idx_max 
		begin
			
			set @band = (select band from #band_table where idx = @sub_idx and [total band] = @tech)			
			set @cmd = 'exec sp_lcc_dropifexists ''cober_3G_'+@band+'''
						select
							cob_3G.entidad,
							cob_3G.mnc,
							SUM(cob_3G.[Cobertura 3G '+@band+' %]) as [Cobertura 3G '+@band+' %]
							into cober_3G_'+@band+'
						from
							(select
								cob.entidad,
								cob.mnc,
								cob.parcel,
								MAX(ISNULL([<=-80 a <-77],0)+ISNULL([<=-77 a <-75],0)+ISNULL([<=-75 a <-72],0)+ISNULL([<=-72 a <-70],0)+ISNULL([<=-70 a <-67],0)+ISNULL([<=-67 a <-66],0)+ISNULL([<=-66 a <-65],0)+ ISNULL([<=-65 a <-62],0)+ ISNULL([<=-62 a <-60],0)+ ISNULL([>=-60],0)) as [Cobertura 3G '+@band+' %]
							from
								filter_cober_'+@tech+' cob,
								[AGRIDS].[dbo].[lcc_parcelas] parcels	 
							where 
								[Database] like ''%'+@scope+'%'' 
								and cob.parcel = parcels.Nombre
								and parcels.entorno like '''+@wild_filter+'''
								and band = '''+@band+'''
								group by cob.entidad,cob.mnc,cob.parcel) cob_3G
						 group by cob_3G.entidad,cob_3g.mnc'
			execute(@cmd)

			if @sub_idx = 1
			begin
				set @cmd = 'select sq3.* into cober_3G_total from (
								select sq1.*,CONVERT(DECIMAL(5,1),ROUND(100.0*sq2.[Cobertura 3G '+@band+' %]/sq1.max_registers,2)) as [Cobertura 3G '+@band+' %] from cober_3G sq1
								left outer join
								cober_3G_'+@band+' sq2 on sq1.entidad = sq2.entidad and sq1.mnc=sq2.mnc) sq3
								
							Drop table cober_3G_'+@band+''
				execute(@cmd) 
			end
			else
			begin
				set @cmd = 'select * into cober_3G_total_aux from cober_3G_total
							drop table cober_3G_total

							select sq3.* into cober_3G_total from (
								select sq1.*,CONVERT(DECIMAL(5,1),ROUND(100.0*sq2.[Cobertura 3G '+@band+' %]/sq1.max_registers,2)) as [Cobertura 3G '+@band+' %] from cober_3G_total_aux sq1
								left outer join
								cober_3G_'+@band+' sq2 on sq1.entidad = sq2.entidad and sq1.mnc=sq2.mnc) sq3
								
							Drop table cober_3G_total_aux
							Drop table cober_3G_'+@band+''
				execute(@cmd)
			end
						
			set @sub_idx = @sub_idx + 1
		end
	end

	IF @idx = 2
	begin
		set @tech='4G'
		set @sub_idx = 1
		set @sub_idx_max = (select MAX(idx) from #band_table where [total band] = @tech)

		set @cmd = 'exec sp_lcc_dropifexists ''cober_4G_Total''
					select
						cob.entidad
						,cob.mnc
						,CONVERT(DECIMAL(5,1),ROUND(100.0*SUM(ISNULL([<=-95 a <-93],0)+ISNULL([<=-93 a <-92],0)+ISNULL([<=-92 a <-90],0)+ISNULL([<=-90 a <-87],0)+ISNULL([<=-87 a <-85],0)+ISNULL([<=-85 a <-84],0)+ISNULL([<=-84 a <-82],0)+ISNULL([<=-82 a <-81],0)+ISNULL([<=-81 a <-80],0)+ISNULL([<=-80 a <-77],0)+ISNULL([<=-77 a <-75],0)+ISNULL([<=-75 a <-72],0)+ISNULL([<=-72 a <-70],0)+ISNULL([<=-70 a <-67],0)+ISNULL([<=-67 a <-66],0)+ISNULL([<=-66 a <-65],0)+ISNULL([<=-65 a <-62],0)+ISNULL([<=-62 a <-60],0)+ISNULL([>=-60],0))/sum(cob.muestras),2)) as [cobertura 4G %]
						,sum(cob.muestras) as max_registers
						into cober_4G 
					from 
						filter_cober_'+@tech+' cob,
						[AGRIDS].[dbo].[lcc_parcelas] parcels	 
					where 
						[Database] like ''%'+@scope+'%'' 
						and cob.parcel = parcels.Nombre
						and parcels.entorno like '''+@wild_filter+'''
						and band is NULL
						group by cob.entidad,cob.mnc'
		
		execute(@cmd)

		while @sub_idx <= @sub_idx_max 
		begin
			
			set @band = (select band from #band_table where idx = @sub_idx and [total band] = @tech)			
			set @cmd = 'exec sp_lcc_dropifexists ''cober_4G_'+@band+'''
						select
							cob_4G.entidad,
							cob_4G.mnc,
							SUM(cob_4G.[Cobertura 4G '+@band+' %]) as [Cobertura 4G '+@band+' %]
							into cober_4G_'+@band+'
						from
							(select
								cob.entidad
								,cob.mnc
								,cob.parcel
								,MAX(ISNULL([<=-95 a <-93],0)+ISNULL([<=-93 a <-92],0)+ISNULL([<=-92 a <-90],0)+ISNULL([<=-90 a <-87],0)+ISNULL([<=-87 a <-85],0)+ISNULL([<=-85 a <-84],0)+ISNULL([<=-84 a <-82],0)+ISNULL([<=-82 a <-81],0)+ISNULL([<=-81 a <-80],0)+ISNULL([<=-80 a <-77],0)+ISNULL([<=-77 a <-75],0)+ISNULL([<=-75 a <-72],0)+ISNULL([<=-72 a <-70],0)+ISNULL([<=-70 a <-67],0)+ISNULL([<=-67 a <-66],0)+ISNULL([<=-66 a <-65],0)+ISNULL([<=-65 a <-62],0)+ISNULL([<=-62 a <-60],0)+ISNULL([>=-60],0)) as [Cobertura 4G '+@band+' %]
							from
								filter_cober_'+@tech+' cob,
								[AGRIDS].[dbo].[lcc_parcelas] parcels
							where 
								[Database] like ''%'+@scope+'%'' 
								and cob.parcel = parcels.Nombre
								and parcels.entorno like '''+@wild_filter+'''
								and band = '''+@band+'''
								group by cob.entidad,cob.mnc,cob.parcel) cob_4G
							group by cob_4G.entidad,cob_4G.mnc'
			execute(@cmd)

			if @sub_idx = 1
			begin
				set @cmd = 'select sq3.* into cober_4G_total from (
								select sq1.*,CONVERT(DECIMAL(5,1),ROUND(100.0*sq2.[Cobertura 4G '+@band+' %]/sq1.max_registers,2)) as [Cobertura 4G '+@band+' %] from cober_4G sq1
								left outer join
								cober_4G_'+@band+' sq2 on sq1.entidad = sq2.entidad and sq1.mnc=sq2.mnc) sq3
								
							Drop table cober_4G_'+@band+''
				execute(@cmd) 
			end
			else
			begin
				set @cmd = 'select * into cober_4G_total_aux from cober_4G_total
							drop table cober_4G_total

							select sq3.* into cober_4G_total from (
								select sq1.*,CONVERT(DECIMAL(5,1),ROUND(100.0*sq2.[Cobertura 4G '+@band+' %]/sq1.max_registers,2)) as [Cobertura 4G '+@band+' %] from cober_4G_total_aux sq1
								left outer join
								cober_4G_'+@band+' sq2 on sq1.entidad = sq2.entidad and sq1.mnc=sq2.mnc) sq3
								
							Drop table cober_4G_total_aux
							Drop table cober_4G_'+@band+''
				execute(@cmd)
			end
						
			set @sub_idx = @sub_idx + 1
		end
	end 
	set @idx = @idx+1
end

--select * from cober_2G_total order by entidad,mnc
select * from cober_3G_total order by entidad,mnc
--select * from cober_4G_total order by entidad,mnc

drop table #band_table
drop table cober_3G_total
drop table cober_3G
drop table cober_4G_total
drop table cober_4G
drop table cober_2G_total