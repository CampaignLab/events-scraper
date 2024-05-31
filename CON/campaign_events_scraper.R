library(RSelenium)
library(httr2)
library(rvest)

con_event_scrape <- function(distance, postcode, first_browser=TRUE, sleep_length = 1){

    scrape_time_start <- Sys.time()

    postcode <- gsub(" ", "+", postcode)

    url <- paste0(
        "https://volunteer.conservatives.com/events?address_change[distance]=", distance, "&email_address=&address_change[submitted_address]=", postcode, "&commit=Search")

    df <- data.frame(
        loop_i = character(),
        event_title = character(), 
        event_type = character(),
        event_location = character(), 
        event_time = character(),
        learn_more_url = character()
        )

    driver$navigate(url) # navigate to the url 

    Sys.sleep(4)

    if (first_browser == TRUE) {
        
        reject_cookies <- driver$findElements(
        "xpath",
        '//*[@id="onetrust-reject-all-handler"]')

        reject_cookies[[1]]$clickElement()

    }

    # Find the last event card using parent Xpath 
    parent_xpath <- "/html/body/main/div[2]/div/div/div[4]/div[2]/div/div/div"

    all_divs <- driver$findElements("xpath", parent_xpath)

    last_div_num <- length(all_divs)

    # Loop through all the div elements

    for (i in seq_len(last_div_num)) {

        # EVENT HEADER

        header <- driver$findElement(
            "xpath", 
            paste0("/html/body/main/div[2]/div/div/div[4]/div[2]/div/div/div[",i,"]/div/div/h2/a"))
        header_t <- header$getElementText() |> unlist()

        # EVENT TYPE
        
        type <- driver$findElement(
            "xpath", 
            paste0("/html/body/main/div[2]/div/div/div[4]/div[2]/div/div/div[",i,"]/div/div/div[1]"))
        type_t <- type$getElementText() |> unlist()

        # EVENT LOCATION 

        location <- driver$findElement(
            "xpath",
            paste0("/html/body/main/div[2]/div/div/div[4]/div[2]/div/div/div[",i,"]/div/div/div[3]/p")
        )
        location_t <- location$getElementText() |> unlist()

        # EVENT TIME 

        time <- driver$findElement(
            "xpath",
            paste0("/html/body/main/div[2]/div/div/div[4]/div[2]/div/div/div[",i,"]/div/div/span")
        )

        time_t <- time$getElementText() |> unlist()

        # LEARN MORE

        more_url <- driver$findElement(
            "xpath",
            paste0("/html/body/main/div[2]/div/div/div[4]/div[2]/div/div/div[",i,"]/div/div/div[4]/a[2]")
            )

        more_url_t <- more_url$getElementAttribute("href")
        more_url_t <- more_url_t |> as.character()
            

        row <- data.frame(
            loop_i = c(i),
            event_title = c(header_t),
            event_type = c(type_t),
            event_location = c(location_t),
            event_time = c(time_t),
            more_url = c(more_url_t)
            )

        df <- rbind(df, row)

        Sys.sleep(sleep_length)

        print(paste0(Sys.time() , " | Event ", i, " of ", last_div_num))
        
    } 

    scrape_time_end <- Sys.time()

    df$scrape_time_start <- scrape_time_start
    df$scrape_time_end <- scrape_time_end

    df$query_postcode <- postcode

    return(df)

    print(paste0(Sys.time() , " | Done"))
}

postcodes <- read.csv("postcodes/postcodes_sample.csv") 

rD <- rsDriver(browser=c("firefox"), verbose = F, port = netstat::free_port(random = TRUE), chromever = NULL) 
driver <- rD$client

date <- substr(Sys.time(), 1, 10)

set.seed(as.numeric(gsub("-", "", date))) # Use date to set the seed

postcodes2 <- postcodes |> dplyr::sample_n(10)

for (i in seq_along(postcodes2$Postcode)) {

    if(i == 1){
        
        con_scrape_df <- con_event_scrape(
            distance = 600,
            postcode = postcodes2$Postcode[i], 
            first_browser = TRUE,
            sleep_length = 0)

        write.csv(
            con_scrape_df, 
            paste0("CON/data/", date, "_", gsub(" ", "_", postcodes$Postcode[i]), "_con-events.csv"))

    } else {
        con_scrape_df <- con_event_scrape(
            distance = 600, 
            postcode = postcodes2$Postcode[i], 
            first_browser = FALSE,
            sleep_length = 0)

        write.csv(
            con_scrape_df, 
            paste0("CON/data/",
            date, "_", gsub(" ", "-", postcodes2$Postcode[i]), "_con-events.csv"))
    }
    print(paste0("Postcode ", i , " of ", length(postcodes2$Postcode), " done."))
}

driver$close()
rD$server$stop()
system("taskkill /im java.exe /f", intern=FALSE, ignore.stdout=FALSE)
