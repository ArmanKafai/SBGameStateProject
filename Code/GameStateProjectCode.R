
library(StatsBombR)
library(dplyr)
library(gt)
library(gtExtras)
library(ggrepel)
library(cowplot)
library(ggplot2)
library (SBpitch)

#Pull Prem

Prem <- FreeCompetitions() %>%
  filter (competition_id == 2 & season_id == 27)

Matches <- FreeMatches(Prem)
StatsBombDataPrem <- StatsBombFreeEvents(MatchesDF = Matches, Parallel = T)
StatsBombDataPremClean = allclean(StatsBombDataPrem)
GameState<-get.gamestate(StatsBombDataPremClean)
StatsBombDataPremClean <- GameState [-2]

StatsBombDataPremClean <- as.data.frame (StatsBombDataPremClean)

#PassData

Prem15Pass <- StatsBombDataPremClean %>%
  filter (type.name == "Pass")


Prem15Pass <- Prem15Pass %>%
  filter (is.na(pass.outcome.name))

Prem15TeamPass <- Prem15Pass %>%
  group_by(team.name, OpposingTeam, match_id, possession, GameState) %>%
  summarise (Pass = n(),
             TimeInPoss=  max (TimeToPossEnd))

Prem15TeamPass$PossValue <- 1

#xG (Team) Data


Prem15Shot <- StatsBombDataPremClean %>%
  filter (type.name == "Shot")


Prem15TeamShot <- Prem15Shot %>%
  group_by(team.name, match_id, OpposingTeam, possession, GameState)%>%
  summarise(xG = sum(shot.statsbomb_xg))


#xG (Player Data)


Prem15ShotIndv <- StatsBombDataPremClean %>%
  filter (type.name == "Shot")%>%
  mutate (Shots = 1)

Prem15ShotIndvTotal <- Prem15ShotIndv %>%
  select (player.name, team.name, shot.statsbomb_xg, GameState, Shots)%>%
  group_by(player.name, team.name, GameState) %>%
  summarise(xG= sum(shot.statsbomb_xg),
            Shots = sum(Shots))

Prem15ShotIndvTotalNoGS <- Prem15ShotIndv %>%
  select (player.name, team.name, shot.statsbomb_xg, Shots)%>%
  group_by(player.name, team.name) %>%
  summarise(xG= sum(shot.statsbomb_xg),
            Shots = sum(Shots))


Prem15ShotIndvTotal<- Prem15ShotIndvTotal %>%
  mutate (xGShot = xG/Shots)



#Merge

Prem15TeamShotPass <- Prem15TeamShot %>%
  right_join(Prem15TeamPass, by =c("team.name", "OpposingTeam", "match_id", "possession", "GameState"))

Prem15TeamShotPass$xG [is.na(Prem15TeamShotPass$xG)] <- 0 

#Total



PremTeamPassShotTotal <- Prem15TeamShotPass %>%
  group_by(team.name)%>%
  summarise (TotalPasses = sum(Pass), 
             TotalPossessions = sum(PossValue),
             TotalTimeInPos = sum(TimeInPoss),
             TotalxG = sum (xG))

PremTeamPassShotFinalTotal <- PremTeamPassShotTotal %>%
  group_by(team.name) %>%
  mutate (PassPerPoss = TotalPasses/TotalPossessions,
          TimePerPoss = TotalTimeInPos/TotalPossessions,
          xGPerPoss = TotalxG/TotalPossessions)

#gameState

PremTeamPassShotTotalGS <- Prem15TeamShotPass %>%
  group_by(team.name, GameState)%>%
  summarise (TotalPasses = sum(Pass), 
             TotalPossesions = sum(PossValue),
             TotalTimeInPos = sum(TimeInPoss),
             TotalxG = sum (xG))

PremTeamPassShotFinalTotalGS <- PremTeamPassShotTotalGS %>%
  group_by(team.name, GameState) %>%
  mutate (PassPerPoss = TotalPasses/TotalPossesions,
          TimePerPoss = TotalTimeInPos/TotalPossesions,
          xGPerPoss = TotalxG/TotalPossesions)


PremTeamPassFinalTotalGS2 <- merge (PremTeamPassShotFinalTotalGS, PremTeamPassShotFinalTotal, by = 'team.name')

PremTeamPassFinalTotalGS2 <- PremTeamPassFinalTotalGS2 %>%
  group_by(team.name, GameState) %>%
  mutate (VarPass = PassPerPoss.x-PassPerPoss.y, 
          VarDuration = TimePerPoss.x-TimePerPoss.y,
          TotalVar = VarPass+VarDuration)

PremTeamPassFinalGS3 <- PremTeamPassFinalTotalGS2 %>%
  group_by(team.name)%>%
  summarise (VarPPP = max(PassPerPoss.x)- min (PassPerPoss.x),
             VarTime = max (TimePerPoss.x)- min (TimePerPoss.x))

##GT Table Game State

#Pull in the logos

Logos <- read.csv ("Prem Logos.csv")

PremTeamPassFinalTotalGS2<- merge (PremTeamPassFinalTotalGS2, Logos, by.x = 'team.name', by.y = 'Team')

DrawTable1 <-PremTeamPassFinalTotalGS2 %>%
  select (ESPN_Link, VarPass, VarDuration, GameState)%>%
  filter (GameState == "Drawing") 

URL1<- DrawTable1$ESPN_Link

Table1<-DrawTable1 %>%
  select(ESPN_Link, VarPass, VarDuration)%>%
  gt() %>%
  opt_all_caps()  %>%
  gt_theme_538() %>%
  tab_header (
    title =md ("**2015-2016 Premier League: Pass Per Poss/Duration Per Poss Deviation From Average**"), 
    subtitle = md ("*Drawing GameState*")
  ) %>%
  #Adds images into table
  text_transform(
    locations=cells_body(c(ESPN_Link)),
    fn=function(x) {
      web_image(
        url=URL1,
        height=px(40)
      )
    } 
  ) %>% cols_align(align="center") %>%
  fmt_number(columns = c(VarPass, VarDuration),
             decimals = 3) %>%
  tab_options(table.font.size =13.5 )%>%
  data_color(
    columns = c(VarPass, VarDuration),
    colors = scales::col_numeric(
      palette = c(
        "firebrick3", "yellow2", "chartreuse3"),
      domain = NULL)
  )%>%
  cols_label(
    ESPN_Link= 'Team', 
    VarPass= 'Passing Per Poss',
    VarDuration = 'Duration Per Poss')%>%
  cols_width(everything() ~ px (100))%>%
  tab_source_note(
    source_note = md ("Data: StatsBomb")
  )


gtsave(Table1, 'DrawingGameState.png', vwidth= 1500, vheight =1000)

#Winning GS

DrawTable2 <-PremTeamPassFinalTotalGS2 %>%
  select (ESPN_Link, VarPass, VarDuration, GameState)%>%
  filter (GameState == "Winning")

URL1<- DrawTable2$ESPN_Link

Table2<-DrawTable2 %>%
  select(ESPN_Link, VarPass, VarDuration)%>%
  gt() %>%
  opt_all_caps()  %>%
  gt_theme_538() %>%
  tab_header (
    title =md ("**2015-2016 Premier League: Pass Per Poss/Duration Per Poss Deviation From Average**"), 
    subtitle = md ("*Winning GameState*")
  ) %>%
  #Adds images into table
  text_transform(
    locations=cells_body(c(ESPN_Link)),
    fn=function(x) {
      web_image(
        url=URL1,
        height=px(40)
      )
    } 
  ) %>% cols_align(align="center") %>%
  fmt_number(columns = c(VarPass, VarDuration),
             decimals = 3) %>%
  tab_options(table.font.size =13.5 )%>%
  data_color(
    columns = c(VarPass, VarDuration),
    colors = scales::col_numeric(
      palette = c(
        "firebrick3", "yellow2", "chartreuse3"),
      domain = NULL)
  )%>%
  cols_label(
    ESPN_Link= 'Team', 
    VarPass= 'Passing Per Poss',
    VarDuration = 'Duration Per Poss')%>%
  cols_width(everything() ~ px (100))%>%
  tab_source_note(
    source_note = md ("Data: StatsBomb")
  )

gtsave(Table2, 'WinningGameState.png', vwidth= 1500, vheight =1000)

#Losing GS

DrawTable3 <-PremTeamPassFinalTotalGS2 %>%
  select (ESPN_Link, VarPass, VarDuration, GameState)%>%
  filter (GameState == "Losing") 

URL1<- DrawTable3$ESPN_Link

Table3<-DrawTable3 %>%
  select(ESPN_Link, VarPass, VarDuration)%>%
  gt() %>%
  opt_all_caps()  %>%
  gt_theme_538() %>%
  tab_header (
    title =md ("**2015-2016 Premier League: Pass Per Poss/Duration Per Poss Deviation From Average**"), 
    subtitle = md ("*Losing GameState*")
  ) %>%
  #Adds images into table
  text_transform(
    locations=cells_body(c(ESPN_Link)),
    fn=function(x) {
      web_image(
        url=URL1,
        height=px(40)
      )
    } 
  ) %>% cols_align(align="center") %>%
  fmt_number(columns = c(VarPass, VarDuration),
             decimals = 3) %>%
  tab_options(table.font.size =13.5 )%>%
  data_color(
    columns = c(VarPass, VarDuration),
    colors = scales::col_numeric(
      palette = c(
        "firebrick3", "yellow2", "chartreuse3"),
      domain = NULL)
  )%>%
  cols_label(
    ESPN_Link= 'Team', 
    VarPass= 'Passing Per Poss',
    VarDuration = 'Duration Per Poss')%>%
  cols_width(everything() ~ px (100))%>%
  tab_source_note(
    source_note = md ("Data: StatsBomb")
  )

gtsave(Table3, 'LosingGameState.png', vwidth= 1500, vheight =1000)


MPPassVar <- mean(PremTeamPassFinalGS3$VarPPP)
MPTimeVar <- mean(PremTeamPassFinalGS3$VarTime)


MidPointPremPass <- mean(PremTeamPassFinalTotal$PassPerPoss)
MidPointPremTime <- mean(PremTeamPassFinalTotal$TimePerPoss)


#Graph

#Total Graph
ggplot(PremTeamPassFinalTotal,aes(PassPerPoss, TimePerPoss, label=team.name)) + 
  geom_point()+
  geom_text_repel(family = "Inter", min.segment.length = unit(0, 'lines'), 
                  nudge_y = .2)+
  labs(x= 'Passes Per Possession', y= "Time Per Possession", title= "2015-16 Prem: Team Styles", caption = 'Data Credit: StatsBomb')+
  theme_cowplot(12)+
  geom_vline(xintercept = MidPointPremPass, linetype="dotted") + 
  geom_hline(yintercept = MidPointPremTime, linetype="dotted") +
  annotate("text", x = 5, y = 30, family = "Inter", label = "Long, Slow Poss. →", fontface = 'bold')+
  annotate("text", x = 4, y = 16, family = "Inter", label = "← Short, Quick Poss. ", fontface = 'bold')+
  annotate("text", x = 5, y = 19, family = "Inter", label = "Avg. Time Per Poss.", fontface = 'italic')+
  annotate("text", x = 4, y = 35, family = "Inter", label = "Avg. Pass Per Poss.", fontface = 'italic')+
  theme(aspect.ratio = 9/16, 
        text=element_text(size= 12, family="Inter", color="black"),
        axis.text.x = element_text(color = 'black'),
        axis.title.x = element_text(color = 'black', face="bold", size=12),
        axis.text.y = element_text(color = 'black'),
        axis.title.y=element_text(color = 'black', face="bold", size=12),
        axis.line.x = element_line(color='black'),
        axis.line.y=element_line(color='black'),
        axis.ticks=element_line(color='black'),
        title=element_text(color = 'black'),
        plot.title = element_text(size = 12, hjust = 0.5, face = "bold"))

ggsave("EPL 2015-16.png")

#Graph 2

ggplot(PremTeamPassFinalGS3,aes(VarPPP, VarTime, label=team.name)) + 
  geom_point()+
  geom_text_repel(family = "Inter", min.segment.length = unit(0, 'lines'), 
                  nudge_y = .05)+
  labs(x= 'Range of Passes Per Possession', y= "Range of Time Per Possession", title= "2015-16 Prem: Team Styles Variation Amongst Game States", caption = 'Data Credit: StatsBomb')+
  theme_cowplot(12)+
  geom_vline(xintercept = MPPassVar, linetype="dotted") + 
  geom_hline(yintercept = MPTimeVar, linetype="dotted") +
  annotate("text", x = .3, y = .1, family = "Inter", label = "Not TOO Much Variation", fontface = 'bold')+
  annotate("text", x = .3, y = 4, family = "Inter", label = "Poss. Duration Variation", fontface = 'bold')+
  annotate("text", x = 1, y = 4, family = "Inter", label = "Variation. Flat Out", fontface = 'bold')+
  theme(aspect.ratio = 9/16, 
        text=element_text(size= 12, family="Inter", color="black"),
        axis.text.x = element_text(color = 'black'),
        axis.title.x = element_text(color = 'black', face="bold", size=12),
        axis.text.y = element_text(color = 'black'),
        axis.title.y=element_text(color = 'black', face="bold", size=12),
        axis.line.x = element_line(color='black'),
        axis.line.y=element_line(color='black'),
        axis.ticks=element_line(color='black'),
        title=element_text(color = 'black'),
        plot.title = element_text(size = 12, hjust = 0.5, face = "bold"))

#Match

PremTeamPass3 <- Prem22TeamPass %>%
  group_by(team.name, OpposingTeam, match_id, GameState)%>%
  summarise (TotalPasses = sum(Pass), 
             TotalPossesions = sum(PossValue),
             TotalTimeInPos = sum(TimeInPoss))

PremTeamPassFinal <- PremTeamPass3 %>%
  group_by(team.name, OpposingTeam, match_id, GameState) %>%
  unite(Match, team.name, OpposingTeam, sep=" vs ", remove = FALSE)%>%
  mutate (PassPerPoss = TotalPasses/TotalPossesions,
          TimePerPoss = TotalTimeInPos/TotalPossesions)

PremTeamPassFinal2 <- merge(PremTeamPassFinal, PremTeamPassFinalTotal, by = "team.name")

PremTeamPassFinalVar <- PremTeamPassFinal2 %>%
  group_by (team.name, Match, GameState)%>%
  mutate (VarPass = PassPerPoss.x-PassPerPoss.y, 
          VarDuration = TimePerPoss.x-TimePerPoss.y,
          TotalVar = VarPass+VarDuration)

#Per Match Graph

ggplot(PremTeamPassFinal,aes(PassPerPoss, TimePerPoss, label=Match)) + 
  geom_point()+
  geom_text_repel(family = "Inter", min.segment.length = unit(0, 'lines'), 
                  nudge_y = .2)+
  labs(x= 'Passes Per Possession', y= "Time Per Possession", title= "2015-16 Prem: Team Styles")+
  theme_cowplot(12)+
  geom_vline(xintercept = 5.127289, linetype="dotted") + 
  geom_hline(yintercept = 22.81001, linetype="dotted") +
  annotate("text", x = 11, y = 30, family = "Inter", label = "Long, Slow Poss. →", fontface = 'bold')+
  annotate("text", x = 4, y = 11, family = "Inter", label = "← Short, Quick Poss. ", fontface = 'bold')+
  annotate("text", x = 11, y = 23.25, family = "Inter", label = "Avg. Time Per Poss.", fontface = 'italic')+
  annotate("text", x = 4.35, y = 40, family = "Inter", label = "Avg. Pass Per Poss.", fontface = 'italic')+
  theme(aspect.ratio = 9/16, 
        text=element_text(size= 12, family="Inter", color="black"),
        axis.text.x = element_text(color = 'black'),
        axis.title.x = element_text(color = 'black', face="bold", size=12),
        axis.text.y = element_text(color = 'black'),
        axis.title.y=element_text(color = 'black', face="bold", size=12),
        axis.line.x = element_line(color='black'),
        axis.line.y=element_line(color='black'),
        axis.ticks=element_line(color='black'),
        title=element_text(color = 'black'),
        plot.title = element_text(size = 12, hjust = 0.5, face = "bold"))

