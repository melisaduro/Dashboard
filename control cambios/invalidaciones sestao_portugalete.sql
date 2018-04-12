use FY1617_Voice_Rest_3G_H2

select *
from sessions s, filelist f
where sessionid in ('54180','54184','53928','53932','54438','54442','54702','54706')
and f.fileid=s.fileid

update sessions
set valid=0, invalidReason='LCC OutOfBounds'
where sessionid in ('54180','54184','53928','53932','54438','54442','54702','54706')

use FY1617_Voice_Rest_4G_H2
select *
from sessions s, filelist f
where sessionid in ('47582','47586','47606','47054','47326','47350','46978','47838','47130','47862','47132','48094','48118','47208')
and f.fileid=s.fileid

update sessions
set valid=0, invalidReason='LCC OutOfBounds'
where sessionid in ('47582','47586','47606','47054','47326','47350','46978','47838','47130','47862','47132','48094','48118','47208')
