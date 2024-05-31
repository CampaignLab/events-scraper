if(!file.exists("postcodes.csv")){
download.file("https://www.doogal.co.uk/files/postcodes.zip", "postcodes/postcodes.zip")


unzip("postcodes/postcodes.zip")
file.remove("postcodes.zip")
}

postcodes <- read.csv("postcodes.csv")


postcodes <- postcodes |>
    dplyr::filter(In.Use. == "Yes") |>
    dplyr::select(Postcode, Constituency, Region)

# Create small random subset of postcodes
set.seed(1019)
postcode_sample <- postcodes |> dplyr::sample_n(500)
write.csv(postcode_sample, "postcodes_sample.csv")
