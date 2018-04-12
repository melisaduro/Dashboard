USE [AGRIDS]
GO

/****** Object:  View [dbo].[vlcc_dashboard_info_scopes_NEW]    Script Date: 07/03/2017 11:50:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER view [dbo].[vlcc_dashboard_info_scopes_NEW]
as
select 
f.type_scope as TYPE_SCOPE,
f.scope as SCOPE,
f.report as REPORT, 
case when f.type_scope='TRANSPORT' then f.[entities_bbdd] else t.[entity_name] end as ENTITIES_BBDD,
f.[entities_dashboard] as ENTITIES_DASHBOARD,
f.order_dashboard as ORDER_DASHBOARD,
f.extension as EXTENSION,
t.pob13 as [POPULATION],
t.RAN_VENDOR_VDF as RAN_VENDOR_VDF,
t.RAN_VENDOR_MOV as RAN_VENDOR_MOV,
t.RAN_VENDOR_OR as RAN_VENDOR_OR,
t.RAN_VENDOR_YOI as RAN_VENDOR_YOI,
t.zona_osp as ZONA_OSP,
t.zona_vf as ZONA_VF,

case when t.PROVINCIA= 'BALEARES' then 'ISLAS_BALEARES' 
	 when t.PROVINCIA= 'CIUDADREAL' then 'CIUDAD_REAL' 
	 when t.PROVINCIA= 'CORUNA' then 'LA_CORUÑA' 
	 when t.PROVINCIA= 'ORENSE' then 'OURENSE' 
	 when t.PROVINCIA= 'PALMAS' then 'LAS_PALMAS' 
	 when t.PROVINCIA= 'RIOJA' then 'LA_RIOJA' 
	 when t.PROVINCIA= 'SCTENERIFE' then 'SANTA_CRUZ_DE_TENERIFE' 
	 else t.PROVINCIA
end as PROVINCIA_DASHBOARD,

case when t.CCAA= 'Castilla León' then 'Castilla y León' 
	 when t.CCAA= 'Catalunya' then 'Cataluña' 
	 when t.CCAA= 'Ceuta' then 'Ciudad Autónoma' 
	 when t.CCAA= 'Islas Canarias' then 'Canarias' 
	 when t.CCAA= 'Madrid' then 'Comunidad de Madrid' 
	 when t.CCAA= 'Melilla' then 'Ciudad Autónoma' 
	 when t.CCAA= 'Pais Vasco' then 'País Vasco' 
	 else t.CCAA 
end as CCAA_DASHBOARD

from agrids.dbo.lcc_dashboard_info_scopes_NEW f
left join agrids_v2.dbo.lcc_ciudades_tipo_Project_V9 t
on entities_bbdd=[entity_name]


GO


