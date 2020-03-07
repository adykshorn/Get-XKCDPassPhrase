Function Get-XKCDPassphrase {
    
    Param ([int]$WordCount = 4
        )

    # First we need to find out the total number of XKCD. The "Prev" link above and below the comic on the main
    # page has the number of the second to last, so we can just grab that and add 1.
    
    $totalXKCD = [int](((((Invoke-WebRequest -Uri "https://xkcd.com/").links | Where-Object {$_.rel -eq "prev"}).href).Trim("/"))[0]) + 1

    # Instead of Get-Random, we're going to generate our own random numbers using the last numbers in the amount
    # bytes of memory in use. So here we need to find out the total number of digits we need to get the number
    # of the random XKCD that we are going to use to build our passphrase.

    $totalDigits = "$totalXKCD".Length

    $XKCDNumber = $totalXKCD + 1 # make sure the loop starts with number greater than the total XKCDs
    While ([decimal]$XKCDNumber -gt $totalXKCD) {
        # Get the appropriate number of digits off the end of in use memory
        $currentRAMUse = ((Get-Counter '\Memory\Available Bytes').CounterSamples).CookedValue
        $endDigits = "$currentRAMUse".Substring("$currentRAMUse".Length - $totalDigits)
    
        # crop off any leading zeros
        $XKCDNumber = $endDigits -replace '^0+'
    }

    $XKCDUri = "https://xkcd.com/$XKCDNumber/"

    # Get the Transcript of the random XKCD and remove punctuation. XKCD transcripts include descriptions of
    # actions going on in the comic -- I'm including the words from those just to add to the word count. 
    $transcript = ((Invoke-WebRequest -Uri $XKCDUri).AllElements | Where-Object {$_.id -eq "transcript"}).innerText
    
    # The below should probably be done with regex, but I don't know regex, so you get this sillyness
    $transcript = $transcript -replace "\[","" -replace "\]","" -replace '\.','' -replace '{','' -replace '}','' -replace '\?','' -replace '!','' -replace ',','' -replace ':','' -replace '"','' -replace '\(','' -replace '\)','' -replace '\<','' -replace '\>',''
 
    $wordArray = $transcript.Split(" ") #split the transcript into an array of individual words
    $wordArrayCount = $wordArray.Count #count the words
    $wordCountDigits = "$wordArrayCount".Length #get how many digits in the word

    # Now I'm going to use digits from the end of in use memory again to get random numbers to pick words out
    # of the word array created from the XKCD transcript
    $i = 1
    While ($i -le $WordCount) {
        # This loop with get a number from in use memory and make sure it's not higher than the number of words in
        # the array. If it is it will try again.
        While ([decimal]$endDigits -gt $wordArrayCount) {
            # Get the appropriate number of digits off the end of in use memory
            $currentRAMUse = ((Get-Counter '\Memory\Available Bytes').CounterSamples).CookedValue
            $endDigits = "$currentRAMUse".Substring("$currentRAMUse".Length - $wordCountDigits)
        }

        # use the random number we generated to get a word from the array and add it to the passphrase
        $passphrase = $passphrase + $wordArray[$endDigits] + " "
        $endDigits = $wordArrayCount + 1
        $i++
    }

    # Create object to return that lets you know the passphrase and the XKCD it was generated from
    $properties = [ordered]@{
        XKCD_Uri = $XKCDUri
        Passphrase = $passphrase
    }
    $object = New-Object -TypeName psobject -Property $properties

    Return $object
}