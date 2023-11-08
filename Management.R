# Script to maintain our database and the for packing excel sheets

#### Packages ####
library("tidyverse")
library("readxl") 
library("openxlsx")
library(excel.link)


#### 1 ####
# To update database with other information
# To be done manually
# E.g., if address, number of clients, children's ages need updating
# Take extra info from the latest request tab on the for packing sheet and update client details in the database
# Remove updated info from for packing sheet
# If name change, remember to change name on requests tab in both spreadsheets


#### 2 ####
# To update database with new clients
# To be done manually
# Take info from the new clients tab on the for packing sheet and update client details in the database
# Remove updated info from for packing sheet
# Check if added to requests tab

# add the unmatched in


#### 3 ####
# To update database with new requests
# Reading in data
folder <- "C:/Users/ridge/OneDrive/Documents/Anya/Files/"
filename_data_base <- paste0(folder, "Database.xlsx")
filename_packing <- paste0(folder, "For packing.xlsx")

password_data_base <- "NULL"
password_packing <- "NULL"

data_base_requests <- xl.read.file(filename_data_base,
                                   xl.sheet = "Requests",
                                   password = password_data_base
                                   )

data_base_details <- xl.read.file(filename_data_base,
                                   xl.sheet = "Details",
                                   password = password_data_base
                                   )

data_packing_details <- xl.read.file(filename_packing,
                                  xl.sheet = "Details",
                                  password = password_packing
                                  )

data_packing_requests <- xl.read.file(filename_packing,
                                      xl.sheet = "Requests OLD",
                                      password = password_packing
                                      )

# Pivoting to long format
new_requests <- data_packing_requests %>%
  mutate(`Last request` = case_when(grepl("-", `Last request`) 
                                      ~ as.Date(`Last request`),
                                    grepl("/", `Last request`)
                                      ~ as.Date(`Last request`, 
                                                format = "%d/%m/%Y"
                                                )
                                    )
         ) %>%
  pivot_longer(names_to = "Request", values_to = "Date", cols = 3:5) %>%
  select(Surname, `First names`, Date) %>%
 # mutate(Date = format(as.Date(Date), "%d/%m/%Y")) %>%
  na.omit() 

# Updating database with unique new requests
data_requests_updated <- data_base_requests %>% 
  mutate(Date = case_when(grepl("-", Date) 
                            ~ as.Date(Date, format = "%Y-%m-%d"),
                          grepl("/", Date)
                          ~ as.Date(Date, 
                                    format = "%d/%m/%Y"
                                    )
                          )
  ) %>%
 # mutate(Date = ifelse(grepl("/", Date), Date, format(as.Date(as.numeric(Date)-1), "%d/%m/%Y"))) %>%
  #mutate(Date = str_replace(Date, "209", "202")) %>%
  rbind(new_requests) %>%
  unique() %>%
  arrange(Surname, `First names`)


#### 4 ####
# To update database with latest request
# Finding latest request for each client
data_requests_last <- data_requests_updated %>%
  group_by(Surname, `First names`) %>%
  summarise("Last request" = max(as.Date(Date, format = "%d/%m/%Y"))) %>%
  mutate("Last request" = format(`Last request`, "%d/%m/%Y")) 

# Adding last request to current detail sheet
data_base_details_update <- data_base_details %>%
  mutate(`Supermarket voucher` = ifelse(`Supermarket voucher` == "Offer supermarket voucher", `Supermarket voucher`, "")) %>%
  select(-Name, -`Last request`) %>%
  left_join(data_requests_last, by = c("Surname", "First names")) %>%
  arrange(Surname, `First names`) %>%
  unique()

# Applying 2, 3 and 4 to workbook
wb_database <- createWorkbook()

addWorksheet(wb_database,
             "Details"
             )

addWorksheet(wb_database,
             "Requests"
)

addWorksheet(wb_database,
             "Last requests"
)

writeData(wb = wb_database,
          sheet = "Details",
          x = data_base_details_update,
          startRow = 2,
          startCol = 2,
          colNames = FALSE
)

writeData(wb = wb_database,
          sheet = "Requests",
          x = data_requests_updated,
          startRow = 2,
          colNames = FALSE
)

writeData(wb = wb_database,
          sheet = "Last requests",
          x = data_requests_last,
          colNames = TRUE
)

saveWorkbook(wb = wb_database,
             file = r"{C:\Users\ridge\OneDrive\Documents\Anya\Backup\update.xlsx}",
             overwrite = TRUE
)


#### 4 ####
# To update for packing sheet with latest info (clients and requests)
# Overwrite file with
# Other info
# New clients
# Latest request
# wb_packing <- loadWorkbook(filename_packing)
# 
# writeData(wb = wb_packing,
#           sheet = "Details",
#           x = data_base_details_update,
#           startRow = 3,
#           startCol = 2,
#           colNames = FALSE
# )
# 
# deleteData(wb = wb_packing, # check that is clear
#            sheet = "Requests",
#            cols = 3:10,
#            rows = 2:nrow(data_requests_updated),
#            gridExpand = TRUE
# )
# 
# writeData(wb = wb_packing,
#           sheet = "Requests",
#           x = data_requests_last,
#           colNames = TRUE
# )
# 
# saveWorkbook(wb = wb_packing,
#              file = filename_packing,
#              overwrite = TRUE
# )
# 
# # Check freeze rows
# 
