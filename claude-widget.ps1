Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

[xml]$xamlDoc = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Width="272" SizeToContent="Height"
    WindowStyle="None" AllowsTransparency="True"
    Background="Transparent" Topmost="True" ResizeMode="NoResize">
  <Border x:Name="RootBorder" CornerRadius="12" BorderThickness="1">
    <StackPanel Margin="18,14,18,14">

      <!-- ===== 전체 보기 ===== -->
      <StackPanel x:Name="FullView">

      <!-- 헤더 -->
      <Grid Margin="0,0,0,10">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock x:Name="CliLabel" Text="CLAUDE CODE" FontSize="9" FontWeight="SemiBold"
                   FontFamily="Segoe UI" VerticalAlignment="Center"/>
        <Border x:Name="MonthBadge" Grid.Column="1" CornerRadius="4"
                Padding="6,2" Margin="0,0,4,0" VerticalAlignment="Center">
          <TextBlock x:Name="MonthText" FontSize="9" FontWeight="Bold" FontFamily="Segoe UI"/>
        </Border>
        <Button x:Name="InfoBtn" Grid.Column="2" Content="&#x24D8;"
                Background="Transparent" BorderThickness="0"
                FontSize="12" Cursor="Hand" Width="18" Height="18"
                VerticalContentAlignment="Center" HorizontalContentAlignment="Center"/>
        <Ellipse x:Name="InfoDot" Grid.Column="2" Width="6" Height="6" Fill="#E5484D"
                 HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,1,0,0"
                 IsHitTestVisible="False" Visibility="Collapsed"/>
        <Button x:Name="ThemeBtn" Grid.Column="3"
                Background="Transparent" BorderThickness="0"
                FontSize="11" Cursor="Hand" Width="18" Height="18"
                VerticalContentAlignment="Center" HorizontalContentAlignment="Center"/>
        <Button x:Name="MinBtn" Grid.Column="4" Content="&#x2013;"
                Background="Transparent" BorderThickness="0"
                FontSize="14" Cursor="Hand" Width="18" Height="18"
                VerticalContentAlignment="Center" HorizontalContentAlignment="Center"/>
        <Button x:Name="CloseBtn" Grid.Column="5" Content="&#x00D7;"
                Background="Transparent" BorderThickness="0"
                FontSize="14" Cursor="Hand" Width="18" Height="18"
                VerticalContentAlignment="Center" HorizontalContentAlignment="Center"/>
      </Grid>

      <!-- 만든이 정보 (ⓘ 클릭 시 펼쳐짐) -->
      <Border x:Name="InfoPanel" Visibility="Collapsed" CornerRadius="6"
              BorderThickness="1" Padding="10,8" Margin="0,0,0,10">
        <Grid x:Name="InfoGrid">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
          </Grid.ColumnDefinitions>
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <TextBlock Grid.Row="0" Grid.Column="0" Text="문의" Opacity="0.6"
                     FontSize="10" FontFamily="Malgun Gothic" Margin="0,0,10,3"/>
          <TextBlock Grid.Row="0" Grid.Column="1" Text="hmchoi@page1.co.kr" FontWeight="SemiBold"
                     FontSize="10" FontFamily="Segoe UI" Margin="0,0,0,3"/>
          <TextBlock Grid.Row="1" Grid.Column="0" Text="이슈" Opacity="0.6"
                     FontSize="10" FontFamily="Malgun Gothic" Margin="0,0,10,3"/>
          <TextBlock Grid.Row="1" Grid.Column="1" FontWeight="SemiBold"
                     FontSize="10" FontFamily="Segoe UI" Margin="0,0,0,3">
            <Hyperlink x:Name="IssueLink" NavigateUri="https://github.com/chm9948/claude-widget/issues"
                       TextDecorations="Underline">버그 신고·개선·건의</Hyperlink>
          </TextBlock>
          <TextBlock Grid.Row="2" Grid.Column="0" Text="버전" Opacity="0.6"
                     FontSize="10" FontFamily="Malgun Gothic" Margin="0,0,10,3"/>
          <TextBlock x:Name="InfoVersion" Grid.Row="2" Grid.Column="1" Text="v1.0.0" FontWeight="SemiBold"
                     FontSize="10" FontFamily="Segoe UI" Margin="0,0,0,3"/>
          <TextBlock x:Name="DownloadLabel" Grid.Row="3" Grid.Column="0" Text="최신" Opacity="0.6"
                     Visibility="Collapsed"
                     FontSize="10" FontFamily="Malgun Gothic" Margin="0,0,10,0"/>
          <StackPanel x:Name="DownloadValue" Grid.Row="3" Grid.Column="1" Orientation="Horizontal"
                      Visibility="Collapsed" Margin="0,0,0,0">
            <Ellipse Width="6" Height="6" Fill="#E5484D" VerticalAlignment="Center" Margin="0,0,5,0"/>
            <TextBlock FontWeight="SemiBold" FontSize="10" FontFamily="Segoe UI">
              <Hyperlink x:Name="DownloadLink" NavigateUri="https://github.com/chm9948/claude-widget/raw/main/claude-widget.exe"
                         TextDecorations="Underline">다운로드</Hyperlink>
            </TextBlock>
          </StackPanel>
        </Grid>
      </Border>

      <!-- 월 누적 비용 -->
      <TextBlock x:Name="CostText" Text="..." FontSize="42" FontWeight="Black"
                 FontFamily="Segoe UI" Margin="0,0,0,2"/>
      <TextBlock x:Name="SubtitleText" Text="이번달 누적 비용" FontSize="10"
                 Margin="0,0,0,10" FontFamily="Malgun Gothic"/>

      <!-- 모델별 바 -->
      <StackPanel x:Name="ModelsPanel" Margin="0,0,0,10"/>

      <!-- 현재 빌링 블록 -->
      <Border x:Name="BlockSection" Visibility="Collapsed"
              CornerRadius="6" Padding="10,10" Margin="0,0,0,10">
        <StackPanel>
          <!-- 라벨 + 비용 -->
          <Grid Margin="0,0,0,6">
            <TextBlock x:Name="BlockLabel" Text="현재 블록" FontSize="9"
                       FontFamily="Malgun Gothic" VerticalAlignment="Center"/>
            <TextBlock x:Name="BlockCost" FontSize="9" FontWeight="Bold"
                       FontFamily="Segoe UI" HorizontalAlignment="Right" VerticalAlignment="Center"/>
          </Grid>
          <!-- 재설정 남은 시간 (크게) -->
          <TextBlock x:Name="BlockRemaining" FontSize="24" FontWeight="Black"
                     FontFamily="Segoe UI" Margin="0,0,0,8"/>
          <!-- 프로그레스바 + % -->
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Grid x:Name="BlockBarGrid" Height="6" VerticalAlignment="Center">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="1*"/>
                <ColumnDefinition Width="99*"/>
              </Grid.ColumnDefinitions>
              <Border Background="#6366F1" CornerRadius="3"/>
              <Border x:Name="BlockBarBg" Grid.Column="1" CornerRadius="3"/>
            </Grid>
            <TextBlock x:Name="BlockPct" Grid.Column="1" FontSize="14" FontWeight="SemiBold"
                       FontFamily="Segoe UI" Margin="10,0,0,0" VerticalAlignment="Center"/>
          </Grid>
        </StackPanel>
      </Border>

      <!-- 하단: 투명도 슬라이더 + 카운트다운 + 새로고침 -->
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="64"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <Slider x:Name="OpacitySlider" Grid.Column="0" Minimum="20" Maximum="100" Value="100"
                SmallChange="5" LargeChange="10" VerticalAlignment="Center"/>
        <TextBlock x:Name="FooterText" Grid.Column="1" FontSize="9"
                   VerticalAlignment="Center" FontFamily="Segoe UI"
                   HorizontalAlignment="Right" TextAlignment="Right" Margin="8,0,4,0"/>
        <Button x:Name="RefreshBtn" Grid.Column="2" Content="&#x21BB;"
                Background="Transparent" BorderThickness="0"
                FontSize="13" Cursor="Hand" Width="16" Height="16"
                VerticalContentAlignment="Center" HorizontalContentAlignment="Center"/>
      </Grid>

      </StackPanel>
      <!-- ===== 최소화 보기 (한 줄) ===== -->
      <Grid x:Name="CompactView" Visibility="Collapsed">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock x:Name="CompactCost" Grid.Column="0" Text="..." FontSize="18" FontWeight="Black"
                   FontFamily="Segoe UI" VerticalAlignment="Center"/>
        <Button x:Name="RestoreBtn" Grid.Column="1" Content="&#x25A2;"
                Background="Transparent" BorderThickness="0"
                FontSize="13" Cursor="Hand" Width="18" Height="18" Margin="6,0,0,0"
                VerticalContentAlignment="Center" HorizontalContentAlignment="Center"/>
        <Button x:Name="CompactCloseBtn" Grid.Column="2" Content="&#x00D7;"
                Background="Transparent" BorderThickness="0"
                FontSize="14" Cursor="Hand" Width="18" Height="18"
                VerticalContentAlignment="Center" HorizontalContentAlignment="Center"/>
      </Grid>

    </StackPanel>
  </Border>
</Window>
"@

# ── 테마 정의 ────────────────────────────────────────────────────────────────
$script:themes = @{
    light = @{
        borderBg      = "#F4F2F2F8"; borderStroke  = "#D0D0EC"
        claudeLabel   = "#8888BB"
        monthBadgeBg  = "#6366F1";   monthText     = "#FFFFFF"
        buttons       = "#AAAACC"
        cost          = "#1E1E3A";   subtitle      = "#5555AA"
        modelName     = "#444466";   barBg         = "#D4D4EE";  modelCost = "#3344BB"
        footer        = "#9999BB"
        blockBg       = "#EEEEF8";   blockLabel    = "#8888BB"
        blockCostFg   = "#1E1E3A";   blockRemFg    = "#5555AA"
        themeIcon     = [char]0x263E
    }
    dark = @{
        borderBg      = "#E0101020"; borderStroke  = "#2A2A6A"
        claudeLabel   = "#7777AA"
        monthBadgeBg  = "#12123A";   monthText     = "#6366F1"
        buttons       = "#666688"
        cost          = "#A5B4FC";   subtitle      = "#6666AA"
        modelName     = "#55556A";   barBg         = "#14141E";  modelCost = "#7879C8"
        footer        = "#555578"
        blockBg       = "#14142A";   blockLabel    = "#7777AA"
        blockCostFg   = "#A5B4FC";   blockRemFg    = "#6666AA"
        themeIcon     = [char]0x2600
    }
}

$script:isDark       = $false
$script:currentData  = $null
$script:blockEndTime = $null
$script:appVersion   = "v1.3.1"   # 변경 시 CHANGELOG.md 에 항목 추가

# ── 윈도우 초기화 ────────────────────────────────────────────────────────────
$reader              = [System.Xml.XmlNodeReader]::new($xamlDoc)
$script:win          = [System.Windows.Markup.XamlReader]::Load($reader)
$script:rootBorder   = $script:win.FindName("RootBorder")
$script:cliLabel     = $script:win.FindName("CliLabel")
$script:monthBadge   = $script:win.FindName("MonthBadge")
$script:monthText    = $script:win.FindName("MonthText")
$script:costText     = $script:win.FindName("CostText")
$script:subtitleText = $script:win.FindName("SubtitleText")
$script:modelsPanel   = $script:win.FindName("ModelsPanel")
$script:blockSection = $script:win.FindName("BlockSection")
$script:blockLabel   = $script:win.FindName("BlockLabel")
$script:blockCost    = $script:win.FindName("BlockCost")
$script:blockRemaining = $script:win.FindName("BlockRemaining")
$script:blockBarGrid  = $script:win.FindName("BlockBarGrid")
$script:blockBarBg    = $script:win.FindName("BlockBarBg")
$script:blockPct      = $script:win.FindName("BlockPct")
$script:footerText   = $script:win.FindName("FooterText")
$script:themeBtn     = $script:win.FindName("ThemeBtn")
$script:closeBtn     = $script:win.FindName("CloseBtn")
$script:fullView     = $script:win.FindName("FullView")
$script:compactView  = $script:win.FindName("CompactView")
$script:compactCost  = $script:win.FindName("CompactCost")
$script:minBtn       = $script:win.FindName("MinBtn")
$script:restoreBtn   = $script:win.FindName("RestoreBtn")
$script:compactCloseBtn = $script:win.FindName("CompactCloseBtn")
$script:infoBtn      = $script:win.FindName("InfoBtn")
$script:infoPanel    = $script:win.FindName("InfoPanel")
$script:infoGrid     = $script:win.FindName("InfoGrid")
$script:infoVersion  = $script:win.FindName("InfoVersion")
$script:issueLink    = $script:win.FindName("IssueLink")
$script:downloadLink = $script:win.FindName("DownloadLink")
$script:downloadLabel = $script:win.FindName("DownloadLabel")
$script:downloadValue = $script:win.FindName("DownloadValue")
$script:infoDot       = $script:win.FindName("InfoDot")
$script:refreshBtn   = $script:win.FindName("RefreshBtn")
$script:opacitySlider= $script:win.FindName("OpacitySlider")

$script:infoVersion.Text = $script:appVersion

$script:win.Add_MouseLeftButtonDown({ $script:win.DragMove() })
$script:closeBtn.Add_Click({ $script:win.Close() })

# 최소화: 금액만 한 줄로 / 복원
$script:minBtn.Add_Click({
    $script:fullView.Visibility    = [System.Windows.Visibility]::Collapsed
    $script:compactView.Visibility = [System.Windows.Visibility]::Visible
    $script:win.Width = 170
})
$script:restoreBtn.Add_Click({
    $script:compactView.Visibility = [System.Windows.Visibility]::Collapsed
    $script:fullView.Visibility    = [System.Windows.Visibility]::Visible
    $script:win.Width = 272
})
$script:compactCloseBtn.Add_Click({ $script:win.Close() })

$script:infoBtn.Add_Click({
    if ($script:infoPanel.Visibility -eq [System.Windows.Visibility]::Visible) {
        $script:infoPanel.Visibility = [System.Windows.Visibility]::Collapsed
    } else {
        $script:infoPanel.Visibility = [System.Windows.Visibility]::Visible
    }
})
# 이슈/다운로드 링크 클릭 시 기본 브라우저로 열기
$openLink = {
    param($s, $e)
    try { Start-Process $e.Uri.AbsoluteUri } catch {}
    $e.Handled = $true
}
$script:issueLink.Add_RequestNavigate($openLink)
$script:downloadLink.Add_RequestNavigate($openLink)

$wa = [System.Windows.SystemParameters]::WorkArea
$script:win.Left = $wa.Right  - 292
$script:win.Top  = $wa.Bottom - 240

# ── 테마 적용 ────────────────────────────────────────────────────────────────
function ConvertTo-Brush { param([string]$h) [System.Windows.Media.BrushConverter]::new().ConvertFrom($h) }

# latest 가 current 보다 새 버전이면 $true (v1.10.0 > v1.9.0 처럼 숫자 비교)
function Test-NewerVersion {
    param([string]$current, [string]$latest)
    if (-not $latest) { return $false }
    $c = ($current -replace '[^\d.]', '').Split('.')
    $l = ($latest  -replace '[^\d.]', '').Split('.')
    for ($i = 0; $i -lt 3; $i++) {
        $cv = if ($i -lt $c.Count -and $c[$i] -ne '') { [int]$c[$i] } else { 0 }
        $lv = if ($i -lt $l.Count -and $l[$i] -ne '') { [int]$l[$i] } else { 0 }
        if ($lv -gt $cv) { return $true }
        if ($lv -lt $cv) { return $false }
    }
    return $false
}

function Apply-Theme {
    param([hashtable]$t)
    $script:currentTheme = $t
    $script:rootBorder.Background      = ConvertTo-Brush $t.borderBg
    $script:rootBorder.BorderBrush     = ConvertTo-Brush $t.borderStroke
    $script:cliLabel.Foreground         = ConvertTo-Brush $t.claudeLabel
    $script:monthBadge.Background      = ConvertTo-Brush $t.monthBadgeBg
    $script:monthText.Foreground       = ConvertTo-Brush $t.monthText
    $script:themeBtn.Foreground        = ConvertTo-Brush $t.buttons
    $script:closeBtn.Foreground        = ConvertTo-Brush $t.buttons
    $script:infoBtn.Foreground         = ConvertTo-Brush $t.buttons
    $script:infoPanel.Background       = ConvertTo-Brush $t.blockBg
    $script:infoPanel.BorderBrush      = ConvertTo-Brush $t.borderStroke
    [System.Windows.Documents.TextElement]::SetForeground($script:infoGrid, (ConvertTo-Brush $t.blockCostFg))
    $script:issueLink.Foreground       = ConvertTo-Brush $t.modelCost
    $script:downloadLink.Foreground    = ConvertTo-Brush $t.modelCost
    $script:costText.Foreground        = ConvertTo-Brush $t.cost
    $script:subtitleText.Foreground    = ConvertTo-Brush $t.subtitle
    $script:minBtn.Foreground          = ConvertTo-Brush $t.buttons
    $script:compactCost.Foreground     = ConvertTo-Brush $t.cost
    $script:restoreBtn.Foreground      = ConvertTo-Brush $t.buttons
    $script:compactCloseBtn.Foreground = ConvertTo-Brush $t.buttons
    $script:blockSection.Background    = ConvertTo-Brush $t.blockBg
    $script:blockLabel.Foreground      = ConvertTo-Brush $t.blockLabel
    $script:blockCost.Foreground       = ConvertTo-Brush $t.blockCostFg
    $script:blockRemaining.Foreground  = ConvertTo-Brush $t.blockRemFg
    $script:blockBarBg.Background      = ConvertTo-Brush $t.barBg
    $script:blockPct.Foreground        = ConvertTo-Brush $t.blockRemFg
    $script:footerText.Foreground      = ConvertTo-Brush $t.footer
    $script:refreshBtn.Foreground      = ConvertTo-Brush $t.buttons
    $script:themeBtn.Content           = $t.themeIcon
    if ($script:currentData) { Update-Display $script:currentData }
}

$script:themeBtn.Add_Click({
    $script:isDark = -not $script:isDark
    $newTheme = if ($script:isDark) { $script:themes.dark } else { $script:themes.light }
    Apply-Theme $newTheme
})


# ── 모델 행 생성 ─────────────────────────────────────────────────────────────
function New-ModelRow {
    param([string]$n, [int]$pct, [string]$mc)
    $f      = [math]::Max(1, $pct)
    $r      = [math]::Max(1, 100 - $f)
    $fw     = "$f*"
    $rw     = "$r*"
    $nameFg = $script:currentTheme.modelName
    $barBg  = $script:currentTheme.barBg
    $costFg = $script:currentTheme.modelCost
    return [System.Windows.Markup.XamlReader]::Parse(@"
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Margin="0,0,0,6">
  <Grid.ColumnDefinitions>
    <ColumnDefinition Width="68"/>
    <ColumnDefinition Width="*"/>
    <ColumnDefinition Width="48"/>
  </Grid.ColumnDefinitions>
  <TextBlock Text="$n" Foreground="$nameFg" FontSize="10" FontFamily="Segoe UI"
             VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
  <Grid Grid.Column="1" Margin="8,0" Height="3" VerticalAlignment="Center">
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="$fw"/>
      <ColumnDefinition Width="$rw"/>
    </Grid.ColumnDefinitions>
    <Border Background="#6366F1" CornerRadius="2"/>
    <Border Grid.Column="1" Background="$barBg" CornerRadius="2"/>
  </Grid>
  <TextBlock Grid.Column="2" Text="$mc" Foreground="$costFg" FontSize="10"
             FontWeight="SemiBold" FontFamily="Segoe UI"
             HorizontalAlignment="Right" VerticalAlignment="Center"/>
</Grid>
"@)
}

# ── 데이터 표시 ──────────────────────────────────────────────────────────────
function Update-Display {
    param([object]$data)
    $script:currentData = $data
    $month = (Get-Date).ToString("yyyy-MM")

    # 월별 데이터
    $cur = $data.monthlyData.monthly | Where-Object { $_.month -eq $month } | Select-Object -First 1
    if (-not $cur) { $cur = $data.monthlyData.monthly | Select-Object -Last 1 }

    $script:monthText.Text = $cur.month
    $script:costText.Text    = '$' + [string]::Format("{0:F2}", $cur.totalCost)
    $script:compactCost.Text = $script:costText.Text
    $script:modelsPanel.Children.Clear()
    $total = [double]$cur.totalCost
    foreach ($m in $cur.modelBreakdowns) {
        $name = ($m.modelName -replace "^claude-", "") -replace "-\d{8,}$", ""
        $pct  = if ($total -gt 0) { [int][math]::Round(($m.cost / $total) * 100) } else { 0 }
        $mc   = '$' + [string]::Format("{0:F2}", $m.cost)
        try { [void]$script:modelsPanel.Children.Add((New-ModelRow $name $pct $mc)) } catch {}
    }

    # 빌링 블록 데이터
    try {
        $activeBlock = $data.blocksData.blocks | Where-Object { $_.isActive -eq $true } | Select-Object -First 1
        if ($activeBlock) {
            $script:blockCost.Text  = '$' + [string]::Format("{0:F2}", $activeBlock.costUSD)
            # 블록 종료 시각: API 값(정확) 우선, 없으면 ccusage endTime 폴백
            $blockEnd = if ($data.apiBlockEndUtc) {
                $ae = $data.apiBlockEndUtc
                if ($ae -is [DateTime]) {
                    [DateTime]::SpecifyKind($ae, [DateTimeKind]::Utc).ToLocalTime()
                } else {
                    [DateTimeOffset]::Parse([string]$ae).LocalDateTime
                }
            } elseif ($activeBlock.endTime -is [DateTime]) {
                $activeBlock.endTime.ToLocalTime()
            } else {
                [DateTimeOffset]::Parse([string]$activeBlock.endTime).LocalDateTime
            }
            $script:blockEndTime    = $blockEnd

            # 사용률: API utilization(/usage 와 동일) 우선, 없으면 token/cost 공식 폴백
            $pct = if ($null -ne $data.apiBlockPct) {
                [int][math]::Min(100, [math]::Max(0, [int]$data.apiBlockPct))
            } else {
                $tokenPct = ($activeBlock.totalTokens / 20446221.0) * 100
                $costPct  = if ($activeBlock.costUSD -gt 0) { ($activeBlock.costUSD / 13.44) * 100 } else { 0 }
                [int][math]::Min(100, [math]::Max(0, [math]::Max($tokenPct, $costPct)))
            }
            $filled    = [math]::Max(1, $pct)
            $empty     = [math]::Max(1, 100 - $filled)

            $script:blockBarGrid.ColumnDefinitions[0].Width = [System.Windows.GridLength]::new($filled, [System.Windows.GridUnitType]::Star)
            $script:blockBarGrid.ColumnDefinitions[1].Width = [System.Windows.GridLength]::new($empty,  [System.Windows.GridUnitType]::Star)
            $script:blockPct.Text = "$pct%"
            $script:blockSection.Visibility = [System.Windows.Visibility]::Visible
        } else {
            $script:blockEndTime = $null
            $script:blockSection.Visibility = [System.Windows.Visibility]::Collapsed
        }
    } catch {}

    # 최신 버전 확인: 저장소 버전이 현재보다 새로우면 "최신" 다운로드 행 표시
    try {
        $latest = [string]$data.latestVersion
        if ($latest -and (Test-NewerVersion $script:appVersion $latest)) {
            $script:downloadLink.Inlines.Clear()
            $script:downloadLink.Inlines.Add([System.Windows.Documents.Run]::new("$latest 다운로드"))
            $script:downloadLabel.Visibility = [System.Windows.Visibility]::Visible
            $script:downloadValue.Visibility = [System.Windows.Visibility]::Visible
            $script:infoDot.Visibility       = [System.Windows.Visibility]::Visible
            $script:infoVersion.Text = $script:appVersion
        } else {
            $script:downloadLabel.Visibility = [System.Windows.Visibility]::Collapsed
            $script:downloadValue.Visibility = [System.Windows.Visibility]::Collapsed
            $script:infoDot.Visibility       = [System.Windows.Visibility]::Collapsed
            $script:infoVersion.Text = if ($latest) { "$($script:appVersion) (최신)" } else { $script:appVersion }
        }
    } catch {}

    $script:isRefreshing  = $false
    $script:lastUpdated   = (Get-Date).ToString("HH:mm:ss")
    $script:nextRefreshAt = [DateTime]::Now.AddSeconds(300)
}

# ── 강제 새로고침 ────────────────────────────────────────────────────────────
$script:refreshBtn.Add_Click({
    $script:isRefreshing = $true
    $script:triggerQueue.Enqueue("refresh")
    $script:nextRefreshAt = [DateTime]::Now.AddSeconds(300)
})

# ── 투명도 슬라이더 ──────────────────────────────────────────────────────────
$script:opacitySlider.Add_ValueChanged({
    $script:win.Opacity = $script:opacitySlider.Value / 100.0
})

# ── 초기 테마 적용 ───────────────────────────────────────────────────────────
Apply-Theme $script:themes.light

# ── CLI 고정 (Claude Code 전용) ──────────────────────────────────────────────
$script:cliSelector = [System.Collections.Generic.List[string]]::new()
$script:cliSelector.Add("claude")

# ── 백그라운드 Runspace ──────────────────────────────────────────────────────
$script:queue        = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
$script:triggerQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

$script:bgRunspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
$script:bgRunspace.Open()
$script:bgPs = [System.Management.Automation.PowerShell]::Create()
$script:bgPs.Runspace = $script:bgRunspace
[void]$script:bgPs.AddScript({
    param($q, $cliSel, $trigQ)
    # 마지막으로 성공한 API 값을 루프 간 유지(캐시). 일시적 429/오류 때 폴백 대신 이 값을 재사용.
    $cachedEndIso    = $null                  # 블록 종료 시각(ISO).
    $cachedPct       = $null                  # 사용률 %.
    $apiBlockedUntil = [DateTime]::MinValue    # 429 백오프 해제 시각(UTC).
    $cachedLatestVer = $null                  # 저장소 최신 버전(CHANGELOG 최상단).
    $lastVerCheck    = [DateTime]::MinValue    # 마지막 버전 확인 시각(UTC) — 1시간 주기.
    while ($true) {
        $cli = $cliSel[0]
        try {
            $monthly = (& npx ccusage@latest $cli monthly --json 2>$null) -join ""
            $blocks  = if ($cli -eq 'claude') {
                           (& npx ccusage@latest $cli blocks --json 2>$null) -join ""
                       } else { '{"blocks":[]}' }

            # 블록 종료 시각 + 사용률은 Anthropic 서버에서 직접 조회.
            # GET /api/oauth/usage 의 five_hour.{resets_at,utilization} 는
            # /usage 와 동일한 값이며 CLI 외 모든 클라이언트(브라우저·앱) 호출까지 포함한다.
            # 토큰은 Claude Code 가 유지하는 ~/.claude/.credentials.json 에서 매번 새로 읽는다.
            $actualEndIso = $null
            $apiPct       = $null
            if ($cli -eq 'claude') {
                # 백오프 중이 아니면 매 주기 호출. 실패하면 캐시값을 계속 표시(폴백 공식으로 튀지 않음).
                if ([DateTime]::UtcNow -ge $apiBlockedUntil) {
                    try {
                        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                        $credPath = [System.IO.Path]::Combine($env:USERPROFILE, '.claude', '.credentials.json')
                        $cred  = Get-Content $credPath -Raw | ConvertFrom-Json
                        $token = $cred.claudeAiOauth.accessToken
                        if ($token) {
                            $hdr  = @{ Authorization = "Bearer $token"; 'anthropic-beta' = 'oauth-2025-04-20' }
                            $resp = Invoke-RestMethod -Uri 'https://api.anthropic.com/api/oauth/usage' -Headers $hdr -TimeoutSec 15
                            $fh   = $resp.five_hour
                            if ($fh) {
                                if ($fh.resets_at) { $cachedEndIso = [DateTimeOffset]::Parse([string]$fh.resets_at).UtcDateTime.ToString('o') }
                                if ($null -ne $fh.utilization) { $cachedPct = [int][math]::Round([double]$fh.utilization) }
                            }
                        }
                    } catch {
                        # 429(rate limit)면 15분, 그 외 오류면 5분 백오프 — 그동안 캐시값으로 계속 표시
                        if ("$($_.Exception.Message)" -match '429' -or "$($_.Exception.Message)" -match 'rate') {
                            $apiBlockedUntil = [DateTime]::UtcNow.AddMinutes(15)
                        } else {
                            $apiBlockedUntil = [DateTime]::UtcNow.AddMinutes(5)
                        }
                    }
                }
                # 캐시값을 표시값으로 사용(성공이든 실패든 마지막으로 알던 정확한 값).
                $actualEndIso = $cachedEndIso
                $apiPct       = $cachedPct

                # 저장소 최신 버전(public raw CHANGELOG 최상단 ## [vX.Y.Z]) 조회 — 1시간 주기
                # (성공하면 1시간 뒤 재확인, 실패하면 다음 사이클에 재시도)
                if (([DateTime]::UtcNow - $lastVerCheck).TotalMinutes -ge 60) {
                    try {
                        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                        $clRaw = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/chm9948/claude-widget/main/CHANGELOG.md' -TimeoutSec 15
                        $lastVerCheck = [DateTime]::UtcNow
                        $vm = [regex]::Match([string]$clRaw, '\[(v\d+\.\d+\.\d+)\]')
                        if ($vm.Success) { $cachedLatestVer = $vm.Groups[1].Value }
                    } catch {}
                }
            }

            if ($monthly -and $blocks) {
                $extra = if ($actualEndIso) { ',"apiBlockEndUtc":"' + $actualEndIso + '"' } else { '' }
                if ($null -ne $apiPct) { $extra += ',"apiBlockPct":' + $apiPct }
                if ($cachedLatestVer) { $extra += ',"latestVersion":"' + $cachedLatestVer + '"' }
                $q.Enqueue('{"monthlyData":' + $monthly + ',"blocksData":' + $blocks + $extra + '}')
            }
        } catch {}
        # 300초(5분) 대기하되 2초마다 수동 트리거 확인
        $waited = 0
        while ($waited -lt 300) {
            Start-Sleep -Seconds 2
            $waited += 2
            $dummy = $null
            if ($trigQ.TryDequeue([ref]$dummy)) { break }
        }
    }
}).AddArgument($script:queue).AddArgument($script:cliSelector).AddArgument($script:triggerQueue)
[void]$script:bgPs.BeginInvoke()

# ── Poll 타이머 (2초) ────────────────────────────────────────────────────────
$script:pollTimer = [System.Windows.Threading.DispatcherTimer]::new()
$script:pollTimer.Interval = [TimeSpan]::FromSeconds(2)
$script:pollTimer.Add_Tick({
    $json = $null; $latest = $null
    while ($script:queue.TryDequeue([ref]$json)) { $latest = $json }
    if ($latest) {
        try { Update-Display ($latest | ConvertFrom-Json) } catch {}
    }
})
$script:pollTimer.Start()

# ── 카운트다운 타이머 (1초) ──────────────────────────────────────────────────
$script:lastUpdated   = ""
$script:nextRefreshAt = [DateTime]::Now.AddSeconds(60)
$script:isRefreshing  = $false

$script:countdownTimer = [System.Windows.Threading.DispatcherTimer]::new()
$script:countdownTimer.Interval = [TimeSpan]::FromSeconds(1)
$script:countdownTimer.Add_Tick({
    # 갱신 카운트다운
    if ($script:isRefreshing) {
        $script:footerText.Text = "갱신 중..."
    } else {
        $secs = [int]([DateTime]$script:nextRefreshAt - [DateTime]::Now).TotalSeconds
        if ($secs -lt 0) { $secs = 0 }
        $cd = if ($secs -ge 60) { "$([math]::Floor($secs / 60))분 $($secs % 60)초 후 갱신" } else { "$($secs)초 후 갱신" }
        $script:footerText.Text = $script:lastUpdated + "  ·  " + $cd
    }

    # 빌링 블록 남은 시간 (1초마다 실시간)
    if ($script:blockEndTime) {
        $rem = $script:blockEndTime - [DateTime]::Now
        if ($rem.TotalSeconds -gt 0) {
            if ($rem.TotalHours -ge 1) {
                # [int] 는 반올림하므로 시간이 1 올라가는 버그가 있음 → Floor 로 내림
                $script:blockRemaining.Text = "$([int][math]::Floor($rem.TotalHours))시간 $($rem.Minutes)분 남음"
            } else {
                $script:blockRemaining.Text = "$($rem.Minutes)분 $($rem.Seconds)초 남음"
            }
        } else {
            $script:blockRemaining.Text = "블록 종료"
        }
    }
})
$script:countdownTimer.Start()

$script:win.Add_Closed({
    $script:pollTimer.Stop()
    $script:countdownTimer.Stop()
    $script:triggerQueue.Enqueue("stop")
    $script:bgPs.Stop()
    $script:bgRunspace.Close()
})

$script:costText.Text   = "로딩 중..."
$script:footerText.Text = ""
$script:win.ShowDialog() | Out-Null
