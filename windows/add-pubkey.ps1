$path=$args
echo $path

function Add-Pub {
	Remove-Item ".\addPubKeyTmp.pub" -ErrorAction Ignore
	ssh-keygen -i -f $args | out-file -append -encoding utf8 ".\addPubKeyTmp.pub" #https://blog.zwindler.fr/2019/01/15/convertir-une-cle-au-format-ssh2-vers-openssh/
    if (Get-Content ".\addPubKeyTmp.pub")
	{	
	    Get-Content ".\addPubKeyTmp.pub" | Add-Content -Path ".\fr.pub"	
	    #Get-Content ".\addPubKeyTmp.pub" | Add-Content -Path "$home\.ssh\authorized_keys"
	    #Get-Content ".\addPubKeyTmp.pub" | Add-Content -Path "C:\ProgramData\ssh\administrators_authorized_keys"
		#
		#$acl = Get-Acl C:\ProgramData\ssh\administrators_authorized_keys
        #$acl.SetAccessRuleProtection($true, $false)
        #$administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators","FullControl","Allow")
        #$systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM","FullControl","Allow")
        #$acl.SetAccessRule($administratorsRule)
        #$acl.SetAccessRule($systemRule)
        #$acl | Set-Acl
	}
	else
	{
		$false
	}
	#Remove-Item ".\addPubKeyTmp.pub" -ErrorAction Ignore
}


if([System.IO.File]::Exists($path))
{
	Add-Pub $path
}
elseif([System.IO.Directory]::Exists($path))
{
	Get-ChildItem $path -Filter *.pub | Foreach-Object { Add-Pub $_ }
}
else
{
	echo error
}

 