﻿Set-StrictMode -Version Latest
function Repair-AzSKAzureServicesSecurity 
{
	<#
	.SYNOPSIS
	This command would help in fixing the security controls for the Azure resources meeting the specified input criteria.

	.PARAMETER ResourceGroupNames
		ResourceGroups for which the security evaluation has to be performed. Comma separated values are supported. Wildcards are not permitted. By default, the command gets all resources in the subscription.
	.PARAMETER ResourceType
		Gets only resources of the specified resource type. Wildcards are not permitted. e.g.: Microsoft.KeyVault/vaults. Run command 'Get-AzSKSupportedResourceTypes' to get the list of supported types.
	.PARAMETER ResourceTypeName
		Friendly name of resource type. e.g.: KeyVault. Run command 'Get-AzSKSupportedResourceTypes' to get the list of supported values.
	.PARAMETER ResourceName
		Gets a resource with the specified name. Wildcards are not permitted. By default, the command gets all resources in the subscription.
	.PARAMETER ParameterFilePath
		ResourceGroups for which the security evaluation has to be performed. Comma separated values are supported. Wildcards are not permitted. By default, the command gets all resources in the subscription.
	.PARAMETER ResourceTypes
			Gets only resources of the specified resource type. Wildcards are not permitted. e.g.: Microsoft.KeyVault/vaults. Run command 'Get-AzSKSupportedResourceTypes' to get the list of supported types.
	.PARAMETER ResourceTypeNames
			Friendly name of resource type. e.g.: KeyVault. Run command 'Get-AzSKSupportedResourceTypes' to get the list of supported values.
	.PARAMETER ResourceNames
			Gets a resource with the specified name. Wildcards are not permitted. By default, the command gets all resources in the subscription.
	.PARAMETER ControlIds
			Comma separated control ids to filter the security controls. e.g.: Azure_Subscription_AuthZ_Limit_Admin_Owner_Count, Azure_Storage_DP_Encrypt_At_Rest_Blob etc.
	.PARAMETER Force
	        Bypass consent to modify Azure resources.
	
	.NOTES
	This command helps the application team to fix the Azure resources for security compliance 

	.LINK
	https://aka.ms/azskossdocs 

	#>
	[OutputType([String])]
	Param
	(

		[string]
        [Parameter(Mandatory = $true, HelpMessage = "ResourceGroups for which the security evaluation has to be performed. Comma seperated values are supported. Wildcards are not permitted. By default, the command gets all resources in the subscription.")]
		$ParameterFilePath,

		#[string]
		#[Parameter(Mandatory = $false, HelpMessage = "Subscription id for which the security evaluation has to be performed.")]
		#$SubscriptionIds,

		[string]
        [Parameter(Mandatory = $false, HelpMessage = "ResourceGroups for which the security evaluation has to be performed. Comma separated values are supported. Wildcards are not permitted. By default, the command gets all resources in the subscription.")]
		$ResourceGroupNames,
        
        [string]
        [Parameter(Mandatory = $false, HelpMessage = "Gets only resources of the specified resource type. Wildcards are not permitted. e.g.: Microsoft.KeyVault/vaults. Run command 'Get-AzSKSupportedResourceTypes' to get the list of supported types.")]
		$ResourceTypes,

		[Parameter(Mandatory = $false, HelpMessage = "Friendly name of resource type. e.g.: KeyVault. Run command 'Get-AzSKSupportedResourceTypes' to get the list of supported values.")]
		[string]
		$ResourceTypeNames,
        
        [string]
		[Parameter(Mandatory = $false, HelpMessage = "Gets a resource with the specified name. Wildcards are not permitted. By default, the command gets all resources in the subscription.")]
		$ResourceNames,

		[string] 
		[Parameter(Mandatory = $false, HelpMessage = "Comma separated control ids to filter the security controls. e.g.: Azure_Subscription_AuthZ_Limit_Admin_Owner_Count, Azure_Storage_DP_Encrypt_At_Rest_Blob etc.")]
		$ControlIds,

		[switch] 
		[Parameter(Mandatory = $false, HelpMessage = "Bypass consent to modify Azure resources.")]
		$Force
    )

	Begin
	{
		[CommandHelper]::BeginCommand($PSCmdlet.MyInvocation);
		[ListenerHelper]::RegisterListeners();
	}

	Process
	{
		try 
		{
			$SubscriptionIds = "";
			$resolver = [FixControlConfigResolver]::new($ParameterFilePath, $SubscriptionIds, $ResourceGroupNames, $ResourceTypes, $ResourceTypeNames, $ResourceNames, $ControlIds);
			if($resolver)
			{
				#currently supporting for only 1 subscription 
				$fixControlParam = $resolver.GetFixControlParameters() | Select-Object -First 1
				if($fixControlParam)
				{
					$controlFixes = [ControlSecurityFixes]::new($fixControlParam.SubscriptionContext.SubscriptionId, $PSCmdlet.MyInvocation, $fixControlParam, $resolver.ConfigFilePath);
					if ($controlFixes) 
					{
						$controlFixes.Force = $Force;
						return $controlFixes.InvokeFunction($controlFixes.ImplementFix);
					}   
				}
			}
		}
		catch 
		{
			[EventBase]::PublishGenericException($_);
		}  
	}

	End
	{
		[ListenerHelper]::UnregisterListeners();
	}
}

function Repair-AzSKSubscriptionSecurity 
{
	<#
	.SYNOPSIS
	This command would help in fixing the security controls for the Azure subscription.

	.NOTES
	This command helps the application team to fix the Azure subscription for security compliance

	.PARAMETER ParameterFilePath
		ResourceGroups for which the security evaluation has to be performed. Comma separated values are supported. Wildcards are not permitted. By default, the command gets all resources in the subscription.
	.PARAMETER Force
	        Bypass consent to modify Azure resources.

	.LINK
	https://aka.ms/azskossdocs 

	#>
	[OutputType([String])]
	Param
	(

		[string]
        [Parameter(Mandatory = $true, HelpMessage = "ResourceGroups for which the security evaluation has to be performed. Comma separated values are supported. Wildcards are not permitted. By default, the command gets all resources in the subscription.")]
		$ParameterFilePath,

		#[string]
		#[Parameter(Mandatory = $false, HelpMessage = "Subscription id for which the security evaluation has to be performed.")]
		#$SubscriptionIds,

		[string] 
		[Parameter(Mandatory = $false, HelpMessage = "Comma separated control ids to filter the security controls. e.g.: Azure_Subscription_AuthZ_Limit_Admin_Owner_Count, Azure_Storage_DP_Encrypt_At_Rest_Blob etc.")]
		$ControlIds,

		[switch] 
		[Parameter(Mandatory = $false, HelpMessage = "Bypass consent to modify Azure resources.")]
		$Force
    )

	Begin
	{
		[CommandHelper]::BeginCommand($PSCmdlet.MyInvocation);
		[ListenerHelper]::RegisterListeners();
	}

	Process
	{
		try 
		{
			$SubscriptionIds = "";
			$resolver = [FixControlConfigResolver]::new($ParameterFilePath, $SubscriptionIds, $ControlIds, $true);
			if($resolver)
			{
				#currently supporting for only 1 subscription 
				$fixControlParam = $resolver.GetFixControlParameters() | Select-Object -First 1
				if($fixControlParam)
				{
					$controlFixes = [ControlSecurityFixes]::new($fixControlParam.SubscriptionContext.SubscriptionId, $PSCmdlet.MyInvocation, $fixControlParam, $resolver.ConfigFilePath);
					if ($controlFixes) 
					{
						$controlFixes.Force = $Force;
						return $controlFixes.InvokeFunction($controlFixes.ImplementFix);
					}   
				}
			}
		}
		catch 
		{
			[EventBase]::PublishGenericException($_);
		}  
	}

	End
	{
		[ListenerHelper]::UnregisterListeners();
	}
}