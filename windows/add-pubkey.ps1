
$path = Convert-Path $args[0]
Write-Host $path

function Add-Pub {
    echo "$args"
	Remove-Item ".\addPubKeyTmp.pub" -ErrorAction Ignore
	ssh-keygen -i -f $args[0] | out-file -append -encoding utf8 ".\addPubKeyTmp.pub" #https://blog.zwindler.fr/2019/01/15/convertir-une-cle-au-format-ssh2-vers-openssh/
    if (Get-Content ".\addPubKeyTmp.pub")
	{
	    Get-Content ".\addPubKeyTmp.pub" | Add-Content -Path "$home\.ssh\authorized_keys"
	    Get-Content ".\addPubKeyTmp.pub" | Add-Content -Path "C:\ProgramData\ssh\administrators_authorized_keys"
		
		$acl = Get-Acl C:\ProgramData\ssh\administrators_authorized_keys
        $acl.SetAccessRuleProtection($true, $false)
        $administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators","FullControl","Allow")
        $systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM","FullControl","Allow")
        $acl.SetAccessRule($administratorsRule)
        $acl.SetAccessRule($systemRule)
        $acl | Set-Acl
	}
	else
	{
		$false
	}
	Remove-Item ".\addPubKeyTmp.pub" -ErrorAction Ignore
}


if(Test-Path -Path $path -PathType Leaf)
{
	Add-Pub $path
}
elseif(Test-Path -Path $path -PathType Container)
{
	Get-ChildItem "$path" -Filter "*.pub" | Foreach-Object {
		Add-Pub $_.FullName
	}
}
else
{
	Write-Host "$path is invalid"
}

 