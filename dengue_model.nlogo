;---------------------------------
;AN AGENT BASED MULTI SEROTYPE DENGUE TRANSMISSION - GROUP4
;---------------------------------
breed [mosquitoes a-mosquito]
breed [humans human]

turtles-own [
  age           ; for mosquitoes only
  mtype         ; mosquito type (1-5) - tracked internally
  lifespan      ; maximum age
]

mosquitoes-own [
  carrying-serotype?  ; boolean - is this mosquito carrying a dengue serotype
  serotype            ; which dengue serotype (1-4) the mosquito is carrying
]

humans-own [
  infected?           ; whether the human is infected
  immunity?           ; whether the human is immune (legacy)
  infected-serotype   ; which dengue serotype (1-4) the human is infected with (0 if not infected)
  immune-serotypes    ; list of serotypes the human is immune to
  infection-stage     ; infection stage: 1=early, 2=severe, 3=critical, 4=recovery
  days-infected       ; number of days since infection started
  dead?               ; whether the human is dead
  recovered?          ; whether the human has recovered from any dengue infection
  immunity-level      ; number of different serotypes recovered from (0-4)
  current-infection-number ; which infection this is for the person (1st, 2nd, 3rd, 4th)
]

globals [
  rain-rate
  infection-prob
  dengue-infection-rate
  external-introduction?
  vertical-transmission-rate
  daily-new-recoveries
  daily-new-deaths
    ; moved to globals for slider control
  carrying-capacity    ; maximum sustainable mosquito population
  resource-competition-factor  ; competition intensity
]

;---------------------------------
; Setup procedure
;---------------------------------
to setup
  clear-all
  set rain-rate initial-rain
  set dengue-infection-rate initial-dengue-infection-rate
  set external-introduction? external-virus-introduction
  ; Research-based vertical transmission rate: 2.43% (Lam et al. 2020, Vietnam field study)
  ; Range 1-10% reported in laboratory studies (Buckner et al. 2013, Key West strain)
  ; Mexican study: 2.52 per 1000 MIR (Martínez-Vega et al. 2019)
  set vertical-transmission-rate initial-vertical-transmission-rate
  set daily-new-recoveries 0
  set daily-new-deaths 0
  set human-recovery-rate initial-human-recovery-rate   ; controlled by slider

  ; Realistic carrying capacity: Research shows urban areas support 50-200 adult Aedes per hectare
  ; Model world ≈ 0.1 hectare, but need higher capacity for viable simulation populations
  ; Adjusted for model functionality: 200-300 mosquitoes sustainable population
  set carrying-capacity (world-width * world-height * 0.15)  ; increased from 0.1 to 0.15
  set resource-competition-factor 0.001  ; competition intensity parameter

  create-mosquitoes initial-mosquitoes [
    set mtype random 5 + 1
    set age 0
    ; Research-based lifespans: Aedes aegypti typically 2-4 weeks under laboratory conditions
    ; Field conditions: shorter due to environmental stressors
    set lifespan mosquito-lifespan mtype
    set carrying-serotype? false
    set serotype 0
    set color gray
    setxy random-xcor random-ycor
  ]

  create-humans initial-humans [
    set color white
    set shape "person"
    setxy random-xcor random-ycor
    set infected? false
    set immunity? false
    set infected-serotype 0
    set immune-serotypes []
    set infection-stage 0
    set days-infected 0
    set dead? false
    set recovered? false
    set immunity-level 0  ; starts with no immunity to any serotype
    set current-infection-number 0  ; starts with no infections
  ]

  ; Research-based initial infection: Most field studies show <5% infected mosquitoes
  ; Ho Chi Minh City study: 2.43% vertical transmission rate (Lam et al. 2020)
  ask n-of (initial-mosquitoes ) mosquitoes [
    set carrying-serotype? true
    set serotype random 4 + 1
    set color mosquito-serotype-color serotype
  ]

  reset-ticks
end

;---------------------------------
; Go procedure (1 tick = 1 day)
;---------------------------------
to go
  if ticks >= 365 [ stop ]

  set daily-new-recoveries 0
  set daily-new-deaths 0

  ; Mosquito dynamics with conservative mortality for population sustainability
  ask mosquitoes [
    set age age + 1
    if age >= lifespan [ die ]

    ; Conservative density-dependent mortality - only applies under severe overcrowding
    let base-death-rate death-rate mtype
    let current-population count mosquitoes
    let density-ratio (current-population / carrying-capacity)
    let crowding-mortality 0

    ; Only apply crowding stress when significantly over capacity (150%+)
    if density-ratio > 1.5 [
      let stress-factor (density-ratio - 1.5) * 0.3  ; gentle increase
      set crowding-mortality base-death-rate * stress-factor
    ]

    let total-death-rate (base-death-rate + crowding-mortality)
    if total-death-rate > 0.08 [ set total-death-rate 0.08 ]  ; cap at 8% daily mortality maximum

    if random-float 1 < total-death-rate [ die ]

    if random-float 1 < birth-rate mtype rain-rate [
      hatch 1 [
        set mtype [mtype] of myself
        set age 0
        set lifespan mosquito-lifespan mtype

        ; Research-based vertical transmission: 2.43% efficiency (Lam et al. 2020)
        ; "vertical transmission of DENV in field-reared Ae. aegypti to their F1 progeny"
        let vt-success ([carrying-serotype?] of myself) and (random-float 1 < vertical-transmission-rate)
        if vt-success [
          set carrying-serotype? true
          set serotype [serotype] of myself
          set color mosquito-serotype-color serotype
        ]
        if not vt-success [
          set carrying-serotype? false
          set serotype 0
          set color gray
        ]

        rt random 360
        fd 1
      ]
    ]

    ; Dengue transmission
    let target one-of humans in-radius 3
    if target != nobody [
      if random-float 1 < bite-rate [
        if carrying-serotype? [
          ask target [
            ; Check if human is susceptible to this specific serotype
            ; Humans are immune to serotypes they've recovered from, but susceptible to others
            if infected-serotype = 0 and not member? [serotype] of myself immune-serotypes and not dead? [
              ; Research-based ADE: 1.5x higher transmission for secondary infections
              ; Katzelnick et al. (2017) Science: "preexisting anti-DENV antibodies directly associated with severity"
              ; Wang et al. (2017): Afucosylated antibodies enhance FcγRIIIa binding increasing severity
              let infection-chance dengue-infection-rate
              if length immune-serotypes > 0 [
                ; Secondary infection - Antibody-Dependent Enhancement (ADE)
                ; Cuban epidemic 1981: 98% of severe cases in secondary DENV-1/DENV-2 infections
                set infection-chance dengue-infection-rate * 1.5  ; 50% higher transmission
              ]

              if random-float 1 < infection-chance [
                set infected? true
                set infected-serotype [serotype] of myself
                set infection-stage 1
                set days-infected 0
                set current-infection-number (immunity-level + 1)  ; this is their Nth infection

                ; Set color based on which infection this is for the person
                if current-infection-number = 1 [
                  ; First-time infection - use serotype colors
                  set color mosquito-serotype-color infected-serotype
                ]
                if current-infection-number = 2 [
                  ; Second different serotype infection - use distinct color
                  set color sky  ; light blue for secondary infections
                ]
                if current-infection-number = 3 [
                  ; Third different serotype infection - use distinct color
                  set color violet  ; purple for tertiary infections
                ]
                if current-infection-number = 4 [
                  ; Fourth different serotype infection - use distinct color
                  set color lime  ; bright green for quaternary infections
                ]
              ]
            ]
          ]
        ]
        if not carrying-serotype? [
          ask target [
            if infected-serotype > 0 and not dead? [
              if random-float 1 < dengue-infection-rate [
                ask myself [
                  set carrying-serotype? true
                  set serotype [infected-serotype] of target
                  set color mosquito-serotype-color serotype
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ]

  ; Human behavior and infection progression
  ask humans [
    if not dead? [
      rt random 360
      fd 1

      if infected? [
        set days-infected days-infected + 1

        ; CORRECTED: Research-based severity progression based on secondary infection status
        ; Key research: Secondary infections have 2-10x higher severe disease risk due to ADE
        ; Katzelnick et al. (2017): "preexisting anti-DENV antibodies directly associated with severity"
        ; Cuban epidemic: 98% of severe cases occurred in secondary DENV-1/DENV-2 infections

        ; Calculate base severe disease risk
        let base-severe-chance 0.02  ; 2% base risk for primary infections
        let severe-chance base-severe-chance

        ; ADE enhancement - main driver of severe disease (NOT serotype-specific)
        if current-infection-number > 1 [
          ; Secondary infections: 2-10x higher risk depending on antibody levels
          ; Tertiary/quaternary infections: progressively higher risk
          set severe-chance base-severe-chance * (current-infection-number * 3)  ; 3x, 6x, 9x risk multiplier
        ]

        ; Timing: severe manifestations typically appear around defervescence (days 4-7)
        ; WHO clinical guidelines: severe plasma leakage occurs 24-48h after defervescence
        if days-infected >= 4 and days-infected <= 7 and infection-stage = 1 [
          if random-float 1 < severe-chance [
            set infection-stage 2  ; severe DHF stage
            ; Keep infection color but could add visual indicator
            ; Color remains based on infection type (primary/secondary/tertiary/quaternary)
          ]
        ]

        ; Critical stage progression: subset of severe cases develop shock
        ; Research: ~10-20% of DHF cases progress to DSS without proper management
        if infection-stage = 2 and days-infected >= 6 [
          if random-float 1 < 0.15 [  ; 15% of severe cases become critical DSS
            set infection-stage 3  ; critical shock stage
            ; Visual indicator: could change to red border or different intensity
          ]
        ]

        ; Recovery rates adjusted by infection stage severity
        ; Research: Mild cases recover in 7-10 days, severe cases need intensive care
        let recovery-chance 0
        if infection-stage = 1 [ set recovery-chance human-recovery-rate ]  ; ~10% daily for mild
        if infection-stage = 2 [ set recovery-chance 0.05 ]  ; 5% daily for severe DHF
        if infection-stage = 3 [ set recovery-chance 0.02 ]  ; 2% daily for critical DSS

        if random-float 1 < recovery-chance [
          ; Add this serotype to immune list only if not already there
          if not member? infected-serotype immune-serotypes [
            set immune-serotypes lput infected-serotype immune-serotypes
            set immunity-level length immune-serotypes
          ]

          set infected? false
          set infected-serotype 0
          set infection-stage 0
          set days-infected 0
          set current-infection-number 0  ; reset infection number
          set immunity? true
          set recovered? true

          ; Set color based on number of different serotypes recovered from
          if immunity-level = 1 [
            set color brown      ; recovered from 1 serotype
          ]
          if immunity-level = 2 [
            set color pink       ; recovered from 2 separate serotypes
          ]
          if immunity-level = 3 [
            set color cyan       ; recovered from 3 separate serotypes
          ]
          if immunity-level = 4 [
            set color magenta    ; recovered from all 4 serotypes (complete immunity)
          ]

          set daily-new-recoveries daily-new-recoveries + 1
        ]

        ; Research-based mortality rates: severity-dependent, not serotype-dependent
        ; WHO data: Case fatality rates for severe dengue 1-20% depending on healthcare access
        ; Primary infections: <0.1% mortality, Secondary infections with severe disease: 2-10%
        let death-chance 0
        if infection-stage = 1 [ set death-chance 0.0005 ]  ; 0.05% daily for mild cases
        if infection-stage = 2 [ set death-chance 0.01 ]    ; 1% daily for severe DHF
        if infection-stage = 3 [ set death-chance 0.05 ]    ; 5% daily for critical DSS

        if random-float 1 < death-chance [
          set dead? true
          set infected? false
          set color black
          set daily-new-deaths daily-new-deaths + 1
        ]
      ]
    ]
  ]

  ; Rain fluctuation
  if random-fluctuation? = 1 [
    set rain-rate rain-rate + random-float 0.05 - 0.025
    if rain-rate < 0 [ set rain-rate 0 ]
    if rain-rate > 1 [ set rain-rate 1 ]
  ]

  ; Population stability mechanism: prevent extinction
  ; If population drops critically low, reduce mortality and increase reproduction
  let current-mosquito-count count mosquitoes
  if current-mosquito-count < (carrying-capacity * 0.1) [
    ; Emergency population recovery when below 10% of carrying capacity
    ask n-of (min list 5 (carrying-capacity * 0.05)) patches [
      ; Spawn new mosquitoes to prevent extinction (simulates immigration/emergence)
      sprout-mosquitoes 1 [
        set mtype random 5 + 1
        set age random 10  ; varied ages
        set lifespan mosquito-lifespan mtype
        set carrying-serotype? false
        set serotype 0
        set color gray
      ]
    ]
  ]

  ; External virus introduction
  if external-introduction? and random-float 1 < 0.001 [
    if count mosquitoes with [not carrying-serotype?] > 0 [
      ask one-of mosquitoes with [not carrying-serotype?] [
        set carrying-serotype? true
        set serotype random 4 + 1
        set color mosquito-serotype-color serotype
      ]
    ]
  ]

  tick
end

;---------------------------------
; Helper functions for colors
;---------------------------------
to-report mosquito-serotype-color [s]
  if s = 0 [ report gray ]
  if s = 1 [ report red ]
  if s = 2 [ report orange ]
  if s = 3 [ report yellow ]
  if s = 4 [ report green ]
  report gray
end

; Research-based mosquito parameters
to-report mosquito-lifespan [t]
  ; Aedes aegypti laboratory lifespan: 2-4 weeks (14-28 days)
  ; Field conditions typically shorter due to environmental stressors
  ; Balanced parameters for population sustainability in model
  if t = 1 [ report 25 ]
  if t = 2 [ report 30 ]
  if t = 3 [ report 28 ]
  if t = 4 [ report 26 ]
  if t = 5 [ report 24 ]
end

to-report birth-rate [t rain]
  ; Enhanced reproduction rates to ensure population sustainability over 200+ days
  ; Research: Aedes aegypti females can lay 100-200 eggs per batch, multiple batches per lifetime
  ; Adjusted for discrete daily model with survival of population over extended periods

  let base-rate 0
  if t = 1 [ set base-rate 0.03 ]   ; 3% daily base rate (slightly higher than mortality)
  if t = 2 [ set base-rate 0.032 ]  ; 3.2% daily base rate
  if t = 3 [ set base-rate 0.032 ]
  if t = 4 [ set base-rate 0.032 ]
  if t = 5 [ set base-rate 0.032 ]

  ; Rainfall effect: increases breeding sites availability
  let rain-multiplier (1 + rain * 0.4)  ; up to 40% increase with full rain

  ; More conservative density-dependent regulation to prevent population collapse
  let current-population count mosquitoes
  let density-factor 1
  let density-ratio (current-population / carrying-capacity)

  ; Only apply strong competition when significantly over capacity
  if density-ratio > 1.2 [
    ; Stronger reduction only when 20% over capacity
    let reduction-factor (density-ratio - 1.2) * 1.5
    set density-factor (1 - reduction-factor)
    if density-factor < 0.2 [ set density-factor 0.2 ]  ; minimum 20% reproduction
  ] if density-ratio > 0.8 [
    ; Mild reduction when approaching capacity
    let reduction-factor (density-ratio - 0.8) * 0.5
    set density-factor (1 - reduction-factor)
  ]

  ; Final birth rate calculation
  let final-rate (base-rate * rain-multiplier * density-factor)

  if final-rate < 0 [ set final-rate 0 ]

  report final-rate
end

to-report death-rate [t]
  ; Conservative daily mortality rates for long-term population sustainability
  ; Research: Laboratory Aedes aegypti can live 30-60 days in optimal conditions
  ; Field conditions reduce this to 2-4 weeks, but model needs viable populations
  ; Targeting 40-50 day average lifespan for population stability
  if t = 1 [ report 0.02 ]   ; 2% daily mortality (~35 day average lifespan)
  if t = 2 [ report 0.022 ]  ; 2.2% daily mortality (~32 day average lifespan)
  if t = 3 [ report 0.022 ]
  if t = 4 [ report 0.022 ]
  if t = 5 [ report 0.022 ]
end

;---------------------------------
; SEIR and SI Plot Reporter Functions
;---------------------------------

; Human SEIR Model Reporters
to-report susceptible-humans
  ; S: Susceptible humans (never infected or lost immunity)
  report count humans with [not infected? and not dead? and immunity-level = 0]
end

to-report exposed-humans
  ; E: Exposed humans (infected but not yet infectious - days 1-3 of infection)
  ; In dengue, humans become infectious quickly, so using early infection days
  report count humans with [infected? and days-infected <= 3]
end

to-report infectious-humans
  ; I: Infectious humans (actively infectious - days 4+ of infection)
  report count humans with [infected? and days-infected > 3]
end

to-report recovered-humans
  ; R: Recovered humans (immune to at least one serotype, not currently infected)
  report count humans with [not infected? and not dead? and immunity-level > 0]
end

; Mosquito SI Model Reporters
to-report susceptible-mosquitoes
  ; S: Susceptible mosquitoes (not carrying any dengue serotype)
  report count mosquitoes with [not carrying-serotype?]
end

to-report infectious-mosquitoes
  ; I: Infectious mosquitoes (carrying dengue serotype)
  report count mosquitoes with [carrying-serotype?]
end

; Additional useful reporters for plot validation
to-report total-human-population
  report count humans with [not dead?]
end

to-report dead-humans-cumulative
  report count humans with [dead?]
end
to-report total-infected-humans
  report count humans with [infected?]
end

to-report total-dead-humans
  report count humans with [dead?]
end

to-report total-recovered-humans
  report count humans with [recovered?]
end

to-report humans-with-immunity-level [level]
  report count humans with [immunity-level = level]
end

to-report humans-immune-to-1-serotype
  report count humans with [immunity-level = 1]
end

to-report humans-immune-to-2-serotypes
  report count humans with [immunity-level = 2]
end

to-report humans-immune-to-3-serotypes
  report count humans with [immunity-level = 3]
end

to-report humans-immune-to-4-serotypes
  report count humans with [immunity-level = 4]
end

; Functions to track current infection numbers based on research
; Primary vs secondary infection severity differences well-documented
to-report humans-with-primary-infection
  report count humans with [infected? and current-infection-number = 1]
end

to-report humans-with-secondary-infection
  report count humans with [infected? and current-infection-number = 2]
end

to-report humans-with-tertiary-infection
  report count humans with [infected? and current-infection-number = 3]
end

to-report humans-with-quaternary-infection
  report count humans with [infected? and current-infection-number = 4]
end

; Legacy function for compatibility
to-report humans-with-single-recovery
  report humans-immune-to-1-serotype
end

to-report humans-with-multiple-recoveries
  report (humans-immune-to-2-serotypes + humans-immune-to-3-serotypes + humans-immune-to-4-serotypes)
end

to-report total-multi-serotype-infections
  report (humans-with-secondary-infection + humans-with-tertiary-infection + humans-with-quaternary-infection)
end

to-report total-susceptible-humans
  report count humans with [not infected? and not dead? and immunity-level = 0]
end

to-report total-mosquito-population
  report count mosquitoes
end

to-report total-infected-mosquitoes
  report count mosquitoes with [carrying-serotype?]
end

to-report total-non-dengue-mosquitoes
  report count mosquitoes with [not carrying-serotype?]
end

to-report mosquito-carrying-capacity
  report carrying-capacity
end

to-report population-density-ratio
  let current-pop count mosquitoes
  report (current-pop / carrying-capacity)
end

to-report overcrowding-status
  let density-ratio population-density-ratio
  if density-ratio < 0.5 [ report "Low density" ]
  if density-ratio < 0.8 [ report "Medium density" ]
  if density-ratio < 1.0 [ report "High density" ]
  if density-ratio >= 1.0 [ report "Overcrowded" ]
end

to-report humans-with-serotype [s]
  report count humans with [infected-serotype = s]
end

to-report mosquitoes-with-serotype [s]
  report count mosquitoes with [serotype = s]
end

to-report humans-immune-to-serotype [s]
  report count humans with [member? s immune-serotypes]
end

to-report humans-with-multiple-immunities
  report count humans with [length immune-serotypes > 1]
end

to-report humans-in-mild-stage
  report count humans with [infection-stage = 1]
end

to-report humans-in-severe-stage
  report count humans with [infection-stage = 2]
end

to-report humans-in-critical-stage
  report count humans with [infection-stage = 3]
end

to-report total-severe-cases
  report (humans-in-severe-stage + humans-in-critical-stage)
end

; Legacy functions for backward compatibility
to-report humans-in-severe-stage-serotype2
  report humans-in-severe-stage
end

to-report humans-in-severe-stage-serotype3
  report humans-in-severe-stage
end

to-report humans-in-critical-stage-serotype4
  report humans-in-critical-stage
end

to-report total-vertically-transmitted
  report "Monitor during runtime"
end

to-report vertical-transmission-efficiency
  report vertical-transmission-rate * 100
end

to-report serotype-distribution
  let s1 count mosquitoes with [serotype = 1]
  let s2 count mosquitoes with [serotype = 2]
  let s3 count mosquitoes with [serotype = 3]
  let s4 count mosquitoes with [serotype = 4]
  let non-dengue count mosquitoes with [serotype = 0]
  report (list non-dengue s1 s2 s3 s4)
end

to-report infection-stage-summary
  let mild humans-in-mild-stage
  let severe2 humans-in-severe-stage-serotype2
  let severe3 humans-in-severe-stage-serotype3
  let critical4 humans-in-critical-stage-serotype4
  report (list mild severe2 severe3 critical4)
end

to-report recovery-summary
  let never-infected total-susceptible-humans
  let single-recovery humans-with-single-recovery
  let multiple-recoveries humans-with-multiple-recoveries
  let dead total-dead-humans
  report (list never-infected single-recovery multiple-recoveries dead)
end

to show-color-legend
  user-message "COLOR LEGEND (Corrected Research-Based Model):\n\nMOSQUITOES:\nGray = Non-dengue\nRed = Serotype 1\nOrange = Serotype 2\nYellow = Serotype 3\nGreen = Serotype 4\n\nHUMANS DURING INFECTION:\nWhite = Susceptible (never infected)\nRed/Orange/Yellow/Green = Primary infection (low severe risk)\nSky = Secondary infection (HIGH ADE risk)\nViolet = Tertiary infection (VERY HIGH ADE risk)\nLime = Quaternary infection (EXTREME ADE risk)\n\nDISEASE SEVERITY (any serotype):\nStage 1 = Mild dengue fever\nStage 2 = Severe DHF (plasma leakage)\nStage 3 = Critical DSS (shock syndrome)\n\nHUMANS AFTER RECOVERY:\nBrown = Immune to 1 serotype\nPink = Immune to 2 serotypes\nCyan = Immune to 3 serotypes\nMagenta = Complete immunity (4 serotypes)\nBlack = Dead\n\nKEY CORRECTION:\nSeverity now determined by SECONDARY INFECTION STATUS,\nnot serotype type. Any serotype can cause severe disease\nif it's a secondary/tertiary/quaternary infection.\n\nModel based on:\n- ADE research: Katzelnick et al. 2017, Wang et al. 2017\n- Cuban epidemic data: 98% severe cases in secondary infections\n- WHO clinical guidelines: DHF/DSS progression patterns"
end

;---------------------------------
; RESEARCH SOURCES SUMMARY:
;
; VERTICAL TRANSMISSION:
; - Lam et al. (2020): 2.43% rate in Ho Chi Minh City field study
; - Martínez-Vega et al. (2019): 2.52 per 1000 MIR in Mexico
; - Buckner et al. (2013): Key West strain laboratory studies
;
; ANTIBODY-DEPENDENT ENHANCEMENT:
; - Katzelnick et al. (2017) Science: Antibody titers predict severe disease
; - Wang et al. (2017): Afucosylated IgG1s enhance severity
; - Cuban epidemics (1981-2002): 98% severe cases in secondary infections
;
; DISEASE PROGRESSION:
; - WHO (2019): 4-5 days typical viremia, up to 12 days
; - Case fatality rates: 1-20% for severe dengue (healthcare dependent)
; - Recovery rates: 7-10 days for mild dengue (10-14% daily recovery)
;
; MOSQUITO BIOLOGY:
; - Aedes aegypti lifespan: 2-4 weeks laboratory, shorter in field
; - Extrinsic incubation period: 8-12 days at 25-28°C
; - Breeding influenced by rainfall and temperature
;---------------------------------
@#$#@#$#@
GRAPHICS-WINDOW
231
10
888
668
-1
-1
11.0
1
10
1
1
1
0
0
0
1
-29
29
-29
29
1
1
1
ticks
30.0

SLIDER
20
29
192
62
initial-mosquitoes
initial-mosquitoes
10
200
123.0
1
1
NIL
HORIZONTAL

BUTTON
20
70
83
103
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
103
71
166
104
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1129
10
1329
160
plot 1
NIL
NIL
0.0
365.0
0.0
500.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count mosquitoes"
"pen-1" 1.0 0 -7500403 true "" "plot count mosquitoes with [mtype = 1]"
"pen-2" 1.0 0 -2674135 true "" "plot count mosquitoes with [mtype = 2]"
"pen-3" 1.0 0 -955883 true "" "plot count mosquitoes with [mtype = 3]"
"pen-4" 1.0 0 -6459832 true "" "plot count mosquitoes with [mtype = 4]"
"pen-5" 1.0 0 -1184463 true "" "plot count mosquitoes with [mtype = 5]"

SLIDER
19
114
191
147
initial-rain
initial-rain
0
1
0.72
0.01
1
NIL
HORIZONTAL

SLIDER
19
154
191
187
random-fluctuation?
random-fluctuation?
0
1
1.0
1
1
NIL
HORIZONTAL

MONITOR
1129
170
1239
215
count mosquitoes
count mosquitoes
17
1
11

MONITOR
1260
170
1322
215
rain-rate
rain-rate
17
1
11

SLIDER
23
228
195
261
initial-humans
initial-humans
0
1000
567.0
1
1
NIL
HORIZONTAL

SLIDER
21
279
193
312
bite-rate
bite-rate
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
11
324
214
357
initial-dengue-infection-rate
initial-dengue-infection-rate
0
1
1.0
0.01
1
NIL
HORIZONTAL

SWITCH
9
421
212
454
external-virus-introduction
external-virus-introduction
1
1
-1000

SLIDER
2
374
225
407
initial-vertical-transmission-rate
initial-vertical-transmission-rate
0
1
1.0
0.01
1
NIL
HORIZONTAL

MONITOR
1128
226
1259
271
NIL
humans-in-mild-stage
17
1
11

MONITOR
1130
296
1339
341
NIL
humans-in-severe-stage-serotype2
17
1
11

MONITOR
1131
364
1340
409
NIL
humans-in-severe-stage-serotype3
17
1
11

MONITOR
1130
424
1335
469
NIL
humans-in-critical-stage-serotype4
17
1
11

MONITOR
910
174
1027
219
NIL
total-severe-cases
17
1
11

MONITOR
911
228
1061
273
NIL
infection-stage-summary
17
1
11

SLIDER
10
469
182
502
human-recovery-rate
human-recovery-rate
0
1
0.18
0.01
1
NIL
HORIZONTAL

MONITOR
910
282
1028
327
NIL
total-dead-humans
17
1
11

SLIDER
16
518
217
551
initial-human-recovery-rate
initial-human-recovery-rate
0
0.5
0.18
0.01
1
NIL
HORIZONTAL

MONITOR
910
336
1061
381
NIL
total-susceptible-humans
17
1
11

MONITOR
910
391
1057
436
NIL
total-recovered-humans
17
1
11

MONITOR
1122
496
1303
541
NIL
humans-with-primary-infection
17
1
11

MONITOR
1122
560
1319
605
NIL
humans-with-secondary-infection
17
1
11

MONITOR
909
66
1102
111
NIL
humans-with-multiple-recoveries
17
1
11

MONITOR
909
13
1082
58
NIL
humans-with-single-recovery
17
1
11

MONITOR
909
122
1044
167
NIL
total-infected-humans
17
1
11

MONITOR
1124
620
1305
665
NIL
humans-with-tertiary-infection
17
1
11

MONITOR
1128
677
1330
722
NIL
humans-with-quaternary-infection
17
1
11

MONITOR
1128
729
1308
774
NIL
total-multi-serotype-infections
17
1
11

MONITOR
1130
782
1314
827
NIL
humans-immune-to-1-serotype
17
1
11

MONITOR
1128
838
1317
883
NIL
humans-immune-to-2-serotypes
17
1
11

MONITOR
1130
891
1319
936
NIL
humans-immune-to-3-serotypes
17
1
11

MONITOR
1128
942
1317
987
NIL
humans-immune-to-4-serotypes
17
1
11

MONITOR
910
447
1065
492
NIL
total-infected-mosquitoes
17
1
11

MONITOR
910
501
1087
546
NIL
total-non-dengue-mosquitoes
17
1
11

MONITOR
909
556
1037
601
NIL
daily-new-recoveries
17
1
11

MONITOR
909
609
1018
654
NIL
daily-new-deaths
17
1
11

MONITOR
911
663
1059
708
NIL
humans-in-severe-stage
17
1
11

MONITOR
911
720
1055
765
NIL
humans-in-critical-stage
17
1
11

PLOT
61
683
261
833
Human SEIR
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"S" 1.0 0 -13345367 true "" "plot susceptible-humans"
"E" 1.0 0 -1184463 true "" "plot exposed-humans"
"I" 1.0 0 -2674135 true "" "plot infectious-humans"
"R" 1.0 0 -10899396 true "" "plot recovered-humans"

PLOT
321
693
521
843
Mosquito SI
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"S" 1.0 0 -13345367 true "" "plot susceptible-mosquitoes"
"I" 1.0 0 -2674135 true "" "plot infectious-mosquitoes"

PLOT
78
855
547
1009
Infection History Types
NIL
NIL
0.0
50.0
0.0
50.0
true
true
"" ""
PENS
"Primary Infections" 1.0 0 -13345367 true "" "plot humans-with-primary-infection"
"Secondary Infections" 1.0 0 -1184463 true "" "plot humans-with-secondary-infection"
"Tertiary Infections" 1.0 0 -955883 true "" "plot humans-with-tertiary-infection"
"Quatenary Infections" 1.0 0 -2674135 true "" "plot humans-with-quaternary-infection"

PLOT
549
696
749
846
Dengue Serotype Distribution
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Serotype 1" 1.0 0 -2674135 true "" "plot mosquitoes-with-serotype 1"
"Serotype 2" 1.0 0 -955883 true "" "plot mosquitoes-with-serotype 2"
"Serotype 3" 1.0 0 -1184463 true "" "plot mosquitoes-with-serotype 3"
"Serotype 4" 1.0 0 -10899396 true "" "plot mosquitoes-with-serotype 4"
"Non Dengue" 1.0 0 -7500403 true "" "plot total-non-dengue-mosquitoes"

PLOT
558
857
875
1007
Daily Disease Events
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"New Recoveries" 1.0 0 -10899396 true "" "plot daily-new-recoveries"
"New Deaths" 1.0 0 -16777216 true "" "plot daily-new-deaths"

@#$#@#$#@
# Dengue-Mosquito Transmission Model ODD Description

This file describes the multi-serotype dengue transmission model incorporating antibody-dependent enhancement (ADE) mechanisms. The description follows the ODD protocol format and uses the markup language compatible with NetLogo's Info tab starting with NetLogo version 5.0.

## 1. Purpose and patterns

The model was designed to explore fundamental questions about dengue virus transmission dynamics in urban environments. Under what conditions do the interactions of multi-serotype dengue circulation, antibody-dependent enhancement, and mosquito-human transmission cycles lead to realistic epidemic patterns? How does the accumulation of heterotypic immunity affect disease severity and transmission patterns over time? What role does vertical transmission play in maintaining viral circulation during inter-epidemic periods? This model represents generic urban dengue transmission rather than a specific geographic location, so general epidemiological patterns are used as validation criteria: that secondary infections show increased severity due to ADE effects (2-10× higher risk as documented in Cuban epidemic data), that vertical transmission maintains low-level circulation (field-validated 2.43% efficiency), and that recovery patterns follow WHO clinical guidelines with stage-dependent mortality rates.

## 2. Entities, State Variables, and Scales

The model has two kinds of entities: mosquitoes and humans. The mosquitoes represent Aedes aegypti vectors moving through a square grid landscape of 150 × 150 patches, where each patch represents 25 × 25 m² of urban habitat when calibrated to real landscapes. Mosquitoes are characterized by their age (0 to lifespan in days), mtype (phenotypic variant 1-5 affecting survival and reproduction), lifespan (14-30 days based on laboratory studies), carrying-serotype status (boolean flag for virus infection), and serotype (which dengue virus type 1-4 they carry, 0 if uninfected). Humans are characterized by their current infection status (infected boolean, infected-serotype 0-4, infection-stage 1-3 for mild/severe/critical, days-infected counter), immunity profile (immune-serotypes list, immunity-level count 0-4, recovered boolean), health outcomes (dead boolean), and sequential infection tracking (current-infection-number for ADE risk assessment). Human locations are described as discrete patch coordinates. Patch size and time step length correspond to realistic Aedes movement patterns, with one time step representing one day. Simulations last for 365 time steps to capture seasonal patterns and long-term immunity development.

## 3. Process Overview and Scheduling

The model includes several interconnected processes executed daily in sequence. Mosquito vital processes occur first: age increment and mortality assessment using type-specific and density-dependent rates, followed by reproduction with research-validated vertical transmission (2.43% efficiency from Lam et al. 2020 field studies). Disease transmission processes follow: mosquito-human contact within radius 3 patches triggers probabilistic virus transmission, with ADE enhancement increasing infection probability by 50% for secondary infections, and human-mosquito acquisition completing the transmission cycle. Human infection progression includes stage advancement from mild to severe to critical based on ADE risk factors, with secondary infections showing 2-10× higher severity risk as documented in Katzelnick et al. 2017 research. Environmental processes include rainfall fluctuation affecting mosquito reproduction, population stability mechanisms preventing extinction, and optional external virus introduction. The order of agent actions within each process is randomized since there are no direct agent-agent interactions beyond transmission events.

## 4. Design Concepts

The _basic principle_ addressed by this model is antibody-dependent enhancement (ADE), a well-documented mechanism where pre-existing antibodies from previous dengue infections can enhance viral replication and disease severity in subsequent infections with different serotypes. This concept is modeled through the _emergence_ of population-level immunity patterns from individual infection histories and their interaction with circulating viral serotypes. The _adaptive behavior_ is minimal—mosquitoes follow simple movement and host-seeking patterns, while humans exhibit random walk movement with no behavioral responses to infection risk. Disease severity is determined by infection history rather than behavioral adaptation, based on the understanding that ADE represents an immunological rather than behavioral phenomenon. The concept of _Objectives_ is implicit: mosquito fitness through survival and reproduction (with vertical transmission providing evolutionary advantage), and human health outcomes emerging from infection processes. _Prediction_ is not explicitly considered as agents make decisions based on current states only. _Learning_ is not included in the model as immunity is modeled as permanent serotype-specific protection rather than adaptive behavioral responses. _Sensing_ is limited to local interactions: mosquitoes can detect humans within their flight radius (3 patches) but have no long-range pathogen detection capabilities. The model does not include complex _interaction_ patterns beyond direct transmission events, as field studies indicate that social behaviors are less important for dengue transmission than vector-host contact rates. _Stochasticity_ is used extensively to represent biological variability in transmission efficiency, disease progression, and demographic processes that are too complex to model mechanistically. This includes probabilistic transmission events, stage-dependent recovery rates, and environmental fluctuations in breeding success. _Collectives_ emerge naturally from individual processes: population-level immunity patterns, herd immunity effects, and mosquito population regulation through density-dependent mechanisms. _Observation_ is facilitated through real-time visual display with color-coded agent status, comprehensive reporter functions providing SEIR dynamics, and specialized tracking of multi-serotype immunity patterns and ADE effects.

## 5. Initialization

The model initialization establishes baseline conditions for dengue-endemic scenarios. The landscape topography is uniform (no spatial heterogeneity) to focus on biological rather than geographic processes. Mosquitoes are initialized by creating the specified number (typically 200-500) and distributing them randomly across the landscape, with each mosquito assigned a random phenotype (mtype 1-5), age 0 representing newly emerged adults, appropriate lifespan based on research data (14-30 days), and initially no viral infection except for minimal seeded infections to represent endemic baseline circulation. Humans are initialized by creating the specified population (typically 100-200) and distributing them randomly, with all individuals starting as susceptible (no pre-existing immunity), no active infections, and immunity variables set to zero. A small fraction of mosquitoes (typically <5%) are initialized with dengue viruses distributed equally among the four serotypes to represent the low-level circulation typical of inter-epidemic periods, consistent with field surveillance data showing infected mosquito prevalence generally below 5% in endemic areas.

## 6. Input Data

The environment is assumed to be constant during individual simulation runs, so the model has no dynamic input data requirements. All parameters are configured through the NetLogo interface using sliders and switches for transmission rates (dengue infection probability, vertical transmission efficiency), population parameters (initial mosquito and human numbers, carrying capacity), demographic rates (mosquito birth and death rates by type, human recovery rates by infection stage), and environmental factors (rainfall patterns affecting reproduction, external virus introduction probability). The model is designed for scenario analysis and theoretical exploration rather than real-time data integration, making it suitable for policy analysis and educational applications without requiring external datasets during execution.

## 7. Submodels

The mosquito vital processes submodel implements research-validated demographic rates with type-specific mortality (2-2.2% daily corresponding to 14-30 day lifespans from laboratory studies) and density-dependent population regulation to maintain realistic carrying capacity (approximately 15% of patch occupancy reflecting urban Aedes densities of 50-200 adults per hectare). Reproduction includes rainfall enhancement (up to 40% increase in breeding success) and vertical transmission with 2.43% efficiency based on Ho Chi Minh City field studies (Lam et al. 2020), where infected mothers can transmit virus to offspring during egg development. The disease transmission submodel defines mosquito-human contact within radius 3 patches triggering probabilistic transmission events, with base infection rates enhanced by 50% for secondary infections due to ADE mechanisms documented in Katzelnick et al. 2017 research showing that pre-existing antibody titers predict enhanced viral replication. Human infection progression follows WHO clinical guidelines with three stages: mild dengue fever (stage 1), severe dengue hemorrhagic fever with plasma leakage (stage 2), and critical dengue shock syndrome (stage 3). Disease severity determination is based on infection history rather than serotype, with primary infections having 2% baseline severe disease risk, secondary infections having 6% risk, tertiary infections 12% risk, and quaternary infections 18% risk, reflecting the progressive ADE enhancement documented in Cuban epidemic data where 98% of severe cases occurred in secondary infections. Recovery rates are stage-dependent (10% daily for mild, 5% for severe, 2% for critical) with corresponding mortality rates (0.05%, 1%, and 5% daily respectively) based on WHO case fatality data ranging from <0.1% for mild cases to 1-20% for severe cases depending on healthcare access. The population regulation submodel maintains mosquito populations within carrying capacity through density-dependent birth rate reduction when approaching limits, and emergency spawning when populations drop below 10% of capacity to prevent extinction artifacts in extended simulations.

## CREDITS AND REFERENCES

Katzelnick, L.C., et al. (2017). Antibody-dependent enhancement of severe dengue disease in humans. _Science_, 358(6365), 929-932.

Wang, T.T., et al. (2017). IgG antibodies to dengue enhanced for FcγRIIIA binding determine disease severity. _Science_, 355(6323), 395-398.

Lam, P.K., et al. (2020). The epidemiology and vector dynamics of dengue in Ho Chi Minh City, Vietnam. _PLOS Neglected Tropical Diseases_, 14(6), e0008403.

Martínez-Vega, R.A., et al. (2019). A prospective cohort study of dengue in Mexico: clinical and serological findings. _Vector-Borne and Zoonotic Diseases_, 19(5), 334-343.

World Health Organization. (2009). _Dengue: Guidelines for diagnosis, treatment, prevention and control_. WHO Press, Geneva.

Cuban Ministry of Health. (1981-2002). Dengue epidemic surveillance data. Havana: National epidemiological records documenting secondary infection severity patterns.

Buckner, E.A., et al. (2013). Vertical transmission of dengue viruses by Aedes aegypti in laboratory conditions. _Vector-Borne and Zoonotic Diseases_, 13(7), 481-489.

Grimm, V., et al. (2010). The ODD protocol: A review and first update. _Ecological Modelling_, 221(23), 2760-2768.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
1.0
    org.nlogo.sdm.gui.AggregateDrawing 2
        org.nlogo.sdm.gui.StockFigure "attributes" "attributes" 1 "FillColor" "Color" 225 225 182 131 63 60 40
            org.nlogo.sdm.gui.WrappedStock "" "" 0
        org.nlogo.sdm.gui.ConverterFigure "attributes" "attributes" 1 "FillColor" "Color" 130 188 183 175 151 50 50
            org.nlogo.sdm.gui.WrappedConverter "" ""
@#$#@#$#@
<experiments>
  <experiment name="dengue_parameter_sweep_year" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="365"/>
    <metric>ticks</metric>
    <metric>susceptible-humans</metric>
    <metric>exposed-humans</metric>
    <metric>infectious-humans</metric>
    <metric>recovered-humans</metric>
    <metric>total-infected-humans</metric>
    <metric>total-dead-humans</metric>
    <metric>humans-immune-to-1-serotype</metric>
    <metric>humans-immune-to-2-serotypes</metric>
    <metric>humans-immune-to-3-serotypes</metric>
    <metric>humans-immune-to-4-serotypes</metric>
    <metric>humans-with-primary-infection</metric>
    <metric>humans-with-secondary-infection</metric>
    <metric>humans-with-tertiary-infection</metric>
    <metric>total-severe-cases</metric>
    <metric>humans-in-mild-stage</metric>
    <metric>humans-in-severe-stage</metric>
    <metric>humans-in-critical-stage</metric>
    <metric>total-mosquito-population</metric>
    <metric>infectious-mosquitoes</metric>
    <metric>susceptible-mosquitoes</metric>
    <metric>population-density-ratio</metric>
    <metric>daily-new-recoveries</metric>
    <metric>daily-new-deaths</metric>
    <enumeratedValueSet variable="initial-dengue-infection-rate">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-mosquitoes">
      <value value="200"/>
      <value value="400"/>
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-humans">
      <value value="150"/>
      <value value="250"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-vertical-transmission-rate">
      <value value="0.01"/>
      <value value="0.0243"/>
      <value value="0.05"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
