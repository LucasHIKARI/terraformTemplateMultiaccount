<#
.SYNOPSIS
    terraformを使用して、ウェブサイトやサーバなどの全てのサービスをクラウドにデプロイ

.DESCRIPTION
    Deploy.ps1 -Config <path>
    Deploy.ps1 -Config <path> -Mode <mode>

.PARAMETER Config
    設定ファイルのパスを指定します

.PARAMETER Mode
    デプロイの環境を指定
    dev: 開発環境
    prod: 本番環境

    パラメタModeの優先度は設定ファイルConfigの中のmodeより高い

.EXAMPLE
    Deploy.ps1 -Config script/config.json    
    Deploy.ps1 -Config script/config.json --Mode dev
#>


param(
    [Parameter(Mandatory = $true)]
    [string]
    $Config,

    [Parameter(Mandatory = $false)]
    [ValidateSet("dev", "prod")]
    [string]
    $Mode,

    [switch]
    $AutoApprove
)

function Write-Linebreak {
    param (
        [int]
        $Length = 25,
        [string]
        $Color = 'DarkGreen',
        [int]
        $Line = 0
    )

    $linebreak = '*' * $Length
    for ($i = 0; $i -lt $Line; $i++) {
        Write-Host
    }
    Write-Host $linebreak -ForegroundColor $Color
}

$PATH_CUR = Get-Location
$CLIENT_NAME = 'client'
$SERVER_NAME = 'server'
$PATH_BUILD = Join-Path $PATH_CUR 'build'
$PATH_WEBSITE = Join-Path $PATH_BUILD $CLIENT_NAME
$PATH_SERVER = Join-Path $PATH_BUILD $SERVER_NAME
$REP_PATH = Join-Path $PATH_BUILD 'repository'
$REP_WEBSITE = Join-Path $REP_PATH $CLIENT_NAME
$REP_SERVER = Join-Path $REP_PATH $SERVER_NAME
$OUTPUT_WEBSITE = Join-Path $PATH_CUR $CLIENT_NAME
$OUTPUT_SERVER = Join-Path $PATH_CUR $SERVER_NAME
$FILE_WEBSITE_URL = Join-Path $PATH_BUILD 'website.url'
$FILE_SERVER_INFO = Join-Path (Join-Path $PATH_CUR 'script') 'server_info.sh'

$PATH_AWS = $PATH_CUR

$tmp = @($PATH_BUILD, $REP_PATH, $OUTPUT_WEBSITE, $OUTPUT_SERVER, $OUTPUT_WEBSITE, $OUTPUT_SERVER)
foreach ($v in $tmp) {
    if (-not (Test-Path $v)) {
        New-Item -Path $v -ItemType Directory
    }
}

$obj = Get-Content -Path $Config -Encoding UTF8 | ConvertFrom-Json -AsHashtable
$client = $obj["client"]
$server = $obj["server"]
$terraform = $obj["terraform"]
#TODO: Config validation

trap {
    Set-Location $PATH_CUR
}

$ErrorActionPreference = "Stop"

function Deploy-BinahAI {
    #####################################################################################
    #                         資産をクラウドにデプロイ
    #####################################################################################
    Write-Linebreak -Length 120 -Line 3
    Write-Host "$(' '*30)資産をクラウドにデプロイ 開始" -ForegroundColor Green
    Write-Linebreak -Length 120

    Set-Location $PATH_AWS
    $rel_mode = $terraform['env']['mode']
    if ($PSBoundParameters.ContainsKey('Mode')) {
        $rel_mode = $Mode 
    }

    terraform init
    $apply_params = @('apply')
    switch ($rel_mode) {
        'test' {
            $apply_params += "-var-file=terraform.tfvars"
        }
        'dev' { 
            $apply_params += "-var-file=terraform.dev.tfvars"
        }
        'prod' {
            # terraform apply -var-file='terraform.prod.tfvars'
            throw "Currently not support the prod mode"
        }
        Default {
            throw "Invlalid terraform apply mode"
        }
    }

    if ($AutoApprove) {
        $apply_params += "-auto-approve"
    }
    terraform @apply_params

    Set-Location $PATH_CUR
}

function Parse-DataBucketName {
    Set-Location $PATH_AWS
    $rel_mode = $terraform['env']['mode']
    if ($PSBoundParameters.ContainsKey('Mode')) {
        $rel_mode = $Mode 
    }

    $lines = @()
    switch ($rel_mode) {
        'test' {
            $lines = Get-Content -Path 'terraform.tfvars' -Encoding UTF8
        }
        'dev' {
            $lines = Get-Content -Path 'terraform.dev.tfvars' -Encoding UTF8
        }
        'prod' {
            throw "Currently not support the prod mode"
        }
        Default {
            throw "Invlalid terraform apply mode"
        }
    }

    foreach ($line in $lines) {
        if ($line -match "^\s*name_data_bucket\s*=\s*(.*)\s*$") {
            return $matches[1].Trim('"')
        }
        if ($line -match "^\s*name\s*=\s*(.*)\s*$") {
            return "$($matches[1].ToLower().Trim('"'))-data"
        }
    }

    return ''
}

#####################################################################################
#                         サーバ資産の取得・更新・ビルド
#####################################################################################
Write-Linebreak -Length 120 -Line 3
Write-Host "$(' '*30)サーバ資産の取得・更新・ビルド 開始" -ForegroundColor Green
Write-Linebreak -Length 120

$data_bucket_name = Parse-DataBucketName
if ([string]::IsNullOrEmpty($data_bucket_name)) {
    throw "terraform.*.tfvarsファイルからデータバッケトの名を解析できませんでした。"
}

if (Test-Path $REP_SERVER) {
    Set-Location $REP_SERVER
    git pull origin
} else {
    Set-Location $REP_PATH
    git clone $server['repository'] $SERVER_NAME
}

Set-Location $REP_SERVER
$branch = 'origin/' + $server['env']['branch']
$output = $PATH_SERVER + '.zip'
$prefix = $SERVER_NAME + '/'
git archive $branch --output=$output --prefix=$prefix

$server_info = @("#$($branch)", "#$($(git rev-parse $branch))")
Set-Content -Path $FILE_SERVER_INFO -Value $server_info

Set-Location $PATH_BUILD
if (Test-Path $PATH_SERVER) {
    Remove-Item -Recurse $PATH_SERVER
}
Expand-Archive -Path $output -DestinationPath $PATH_BUILD -Force

Set-Location $PATH_SERVER
Copy-Item $FILE_SERVER_INFO ./
$server_config = Get-Content Config.json -Encoding UTF8 | ConvertFrom-Json
$server_config.S3.BucketName = $data_bucket_name
$server_config | ConvertTo-Json | Set-Content -Path Config.json

$output = Join-Path $OUTPUT_SERVER "$($SERVER_NAME).zip"
Compress-Archive -Path "$PATH_SERVER" -DestinationPath $output -Force

Deploy-BinahAI

Set-Location $PATH_AWS
terraform output website_url > $FILE_WEBSITE_URL

#####################################################################################
#                         画面資産の取得・更新・ビルド
#####################################################################################
Write-Linebreak -Length 120 -Line 3
Write-Host "$(' '*30)画面資産の取得・更新・ビルド 開始" -ForegroundColor Green
Write-Linebreak -Length 120

if (Test-Path $REP_WEBSITE) {
    Set-Location $REP_WEBSITE
    git pull origin
} else {
    Set-Location $REP_PATH
    git clone $client['repository'] $CLIENT_NAME
}

Set-Location $REP_WEBSITE
$branch = 'origin/' + $client['env']['branch']
$output = $PATH_WEBSITE + '.zip'
$prefix = $CLIENT_NAME + '/'
git archive $branch --output=$output --prefix=$prefix

Set-Location $PATH_BUILD
if (Test-Path $PATH_WEBSITE) {
    Set-Location $PATH_WEBSITE
    Get-ChildItem './' -Exclude 'node_modules' | Remove-Item -Recurse
}
Expand-Archive -Path $output -DestinationPath $PATH_BUILD -Force

Set-Location $PATH_WEBSITE
$website_url = (Get-Content $FILE_WEBSITE_URL -Encoding UTF8).Trim('"')
$vite_config_path = Join-Path (Join-Path . config) '.env.production'
$lines = Get-Content -Path $vite_config_path -Encoding UTF8
$lines = $lines | ForEach-Object {
    if ($_ -match "^VITE_API_BASE_URL=") {
        "VITE_API_BASE_URL=https://$($website_url)"
    } else {
        $_
    }
}
$lines | Set-Content -Path $vite_config_path
npm install
npm run build

$dist = Join-Path $PATH_WEBSITE 'dist'
if (Test-Path $dist) {
    Remove-Item -Recurse (Join-Path $OUTPUT_WEBSITE '*')
    Copy-Item -Recurse (Join-Path $dist '*') -Destination $OUTPUT_WEBSITE
}


Deploy-BinahAI