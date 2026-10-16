"""Compatibility fix for IIC 2026.09 OpenSTA scene handles; run inside container."""
from pathlib import Path
import shutil
p=Path('/usr/local/lib/python3.12/dist-packages/librelane/scripts/openroad/common/io.tcl')
s=p.read_text()
old='''            return [sta::scenes]'''
new='''            set result [list]
            foreach scene [sta::scenes] {
                lappend result [sta::get_name $scene]
            }
            return $result'''
old3='''            sta::set_cmd_scene $corner_name'''
new3='''            sta::set_cmd_scene [sta::find_scene $corner_name]'''
old2='''                dict set result $scene $scene'''
new2='''                dict set result [sta::get_name $scene] $scene'''
if old in s and old2 in s:
    shutil.copy2(p, str(p)+'.dvd-original')
    p.write_text(s.replace(old,new).replace(old2,new2).replace(old3,new3))
    print('Applied scene handle/name compatibility fix; original backed up.')
elif new in s and new2 in s:
    p.write_text(s.replace(old3,new3))
    print('Fix already applied; scene selection adapted.')
else:
    raise SystemExit('Unexpected script version; refusing to patch.')
