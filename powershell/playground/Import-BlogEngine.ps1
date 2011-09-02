$Site = "http://dev.patton-tech.com"
$SitePath = "blog/lists/categories"
$blogPosts = Get-ChildItem -Path .\posts -Recurse
[xml]$blogCategories = Get-Content -Path .\categories.xml
#
# Get the categories and tags into a PSObject
#
$blogEntries = @()
foreach ($blogPost in $blogPosts)
{
    $Categories = @()
    [xml]$blogEntry = Get-Content -Path $blogPost.FullName
    #
    # Skip empty categories
    #
    if ($blogEntry.post.categories.category -ne $null)
    {
        foreach ($Category in $blogEntry.post.categories.category)
        {
            foreach ($Entry in $blogCategories.categories.category)
            {
                if ($Entry.Id -eq $Category)
                {
                    $ThisCategory = New-Object -TypeName PSObject -Property @{
                        Name = $Entry.InnerText
                        }
                    }
                $Categories += $ThisCategory
                }
            }
        }
    #
    # Skip empty tags
    #
    if ($blogEntry.post.tags.tag -ne $null)
    {
        foreach ($category in $blogEntry.post.tags.tag)
        {
            $ThisCategory = New-Object -TypeName PSObject -Property @{
                Name = $Category
                }
            $Categories += $ThisCategory
            }
        }
    #
    # Remove duplicate categories
    #
    $Categories = $Categories |Select-Object -Property Name -Unique |Sort-Object -Property Name
    $ThisEntry = New-Object -TypeName PSObject -Property @{
        Title = $blogEntry.post.title
        Content = $blogEntry.post.content
        PubDate = $blogEntry.post.pubDate
        Slug = $blogEntry.post.slug
        Categories = $Categories
        }
    $blogEntries += $ThisEntry
    }
#
# Sort posts in ascending order by pubDate
#
$blogEntries = $blogEntries |Sort-Object -Property pubDate

#
# Add posts to blog
#
foreach($blogEntry in $blogEntries)
{
    $SPWeb = Get-SPWeb -Identity http://dev.patton-tech.com
    $SPPosts = $SPWeb.GetList("Blog/Lists/Posts/")
    $SPPost = $SPPosts.AddItem()
    $PostCategories = New-Object Microsoft.Sharepoint.SPFieldMultiChoiceValue($null)
    $SPBlogPath = "/Blog/SiteAssets"
    
    #
    # Get a list of available categories
    #
    $SPCategories = Get-SPListIds -Site $Site -SitePath $SitePath
    foreach ($blogCategory in $blogEntry.Categories)
    {
        #
        # If the category isn't on the server add it
        #
        if ($blogCategory.Name)
        {
            if ((Get-SPListItem -Site $Site -SitePath $SitePath -LookupValue $blogCategory.Name) -eq $null)
            {
                $NewCategoryID = New-SPListItem -Site $Site -SitePath $SitePath -ItemValue $blogCategory.Name
                }
            $WorkingCategory = Get-SPListItem -Site $Site -SitePath $SitePath -LookupValue $blogCategory.Name
            $postCategory = New-Object Microsoft.Sharepoint.SPFieldLookupValue($WorkingCategory.ID, $WorkingCategory.Title)
            $PostCategories.Add($postCategory)
            }
        }
    # Pull the images from each post
    #
    $blogLinks = Get-MarkupTag -tag a $blogEntry.Content
    If ($blogLinks -ne $null)
    {
        foreach ($blogLink in $blogLinks)
        {
            if($blogLink.tag.indexof("src") -ne -1)
            {
                $startHref = $blogLink.tag.indexof("href")
                $endHref = $blogLink.tag.indexof("`"",$startHref+6)
                $url = $blogLink.Tag.Substring($startHref+6,($endHref-$startHref)-6)
                if ($url.IndexOf("media") -ne -1)
                {
                    $startFile = $url.IndexOf("media/")
                    $filename = $url.Substring($startFile+6,($url.Length-$startFile)-6)
                    $NewURL = "$($blogPath)/$($blogEntry.Slug)/$($FileName)"
                    $blogEntry.Content = $blogEntry.Content.Replace($blogLink, $NewURL)
                    }
                elseif($url.IndexOf("image.axd?picture=") -ne -1)
                {
                    $startFile = $url.IndexOf("image.axd?picture=")
                    $filename = $url.Substring($startFile+18,($url.Length-$startFile)-18)
                    $NewURL = "$($blogPath)/$($blogEntry.Slug)/$($FileName)"
                    $blogEntry.Content = $blogEntry.Content.Replace($blogLink, $NewURL)
                    }
                elseif ($url.IndexOf("files") -ne -1)
                {
                    $startFile = $url.IndexOf("files/")
                    $filename = $url.Substring($startFile+6,($url.Length-$startFile)-6)
                    $NewURL = "$($blogPath)/$($blogEntry.Slug)/$($FileName)"
                    $blogEntry.Content = $blogEntry.Content.Replace($blogLink, $NewURL)
                    }
                New-Item -Name $blogEntry.slug -ItemType Directory -Force
                New-SPDocLibFolder -Site $Site -SitePath $SPBlogPath -Folder $blogEntry.Slug
                Get-Web -url $url -toFile ".\$($blogEntry.slug)\$($filename)"
                $FileName = Get-ChildItem ".\$($blogEntry.slug)\$($filename)"
                Add-SPFileToDocLib -Site $Site -SitePath $SPBlogPath/$blogEntry.Slug -FilePath $FileName
                $startSrc = $blogLink.Tag.indexof("src")
                $endSrc = $blogLink.Tag.indexof("`"",$startSrc+5)
                $url = $blogLink.Tag.Substring($startSrc+5,($endSrc-$startSrc)-5)
                if ($url.IndexOf("media") -ne -1)
                {
                    $startFile = $url.IndexOf("media/")
                    $filename = $url.Substring($startFile+6,($url.Length-$startFile)-6)
                    $NewURL = "$($blogPath)/$($blogEntry.Slug)/$($FileName)"
                    $blogEntry.Content = $blogEntry.Content.Replace($blogLink, $NewURL)
                    }
                elseif($url.IndexOf("image.axd?picture=") -ne -1)
                {
                    $startFile = $url.IndexOf("image.axd?picture=")
                    $filename = $url.Substring($startFile+18,($url.Length-$startFile)-18)
                    $NewURL = "$($blogPath)/$($blogEntry.Slug)/$($FileName)"
                    $blogEntry.Content = $blogEntry.Content.Replace($blogLink, $NewURL)
                    }
                New-Item -Name $blogEntry.slug -ItemType Directory -Force
                New-SPDocLibFolder -Site $Site -SitePath $SPBlogPath -Folder $blogEntry.Slug
                Get-Web -url $url -toFile ".\$($blogEntry.slug)\$($filename)"
                $FileName = Get-ChildItem ".\$($blogEntry.slug)\$($filename)"
                Add-SPFileToDocLib -Site $Site -SitePath $SPBlogPath/$blogEntry.Slug -FilePath $FileName
                }
            }
        }
   $SPPost["Title"] = $blogEntry.Title
   $SPPost["Body"] = $blogEntry.Content
   $SPPost["Published"] = $blogEntry.PubDate
   $SPPost["Category"] = $PostCategories
   $CurrentDate = Get-Date
   #
   # Preserve the date the entry was posted to the server
   #
   Set-Date -Date $blogEntry.PubDate
   $SPPost.Update()
   #
   # Reset to today's date
   #
   Set-Date -Date $CurrentDate
   $SPWeb.Close()
    }