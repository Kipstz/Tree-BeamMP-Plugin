print(coucouc)
print(hole) 

print("^0Black text^r")
print("^1Blue text^r")
print("^2Green text^r") 
print("^3Light blue text^r")
print("^4Red text^r")
print("^5Pink text^r")
print("^6Orange text^r")
print("^7Grey text^r")
print("^8Dark grey text^r")
print("^9Light purple text^r")
print("^aLight green text^r")
print("^bLight blue text^r")
print("^cDark orange text^r")
print("^dLight pink text^r")
print("^eYellow text^r")
print("^fWhite text^r")

print("^lBold text^r")
print("^nUnderlined text^r")
print("^oItalic text^r")
print("^mStrike-through text^r")

print("^2Mixed ^4colors ^l^6with ^n^ebold ^o^aand ^m^deffects^r")

print("cocococuococuuocc")

CreateThread(function()
      Wait(1000)
      print("coucouc")
end)

print("caca")

function MyHandler()
      print("cmd: MyHandler")
end


MP.RegisterEvent("MyCoolCustomEvent", "MyHandler")

MP.RegisterEvent("onConsoleInput", function()
      MP.TriggerGlobalEvent("MyCoolCustomEvent")
end)
MP.RegisterEvent("onConsoleInput", function()
      MP.TriggerGlobalEvent("MyCoolCustomEvent")
end)
MP.RegisterEvent("onConsoleInput", function()
      MP.TriggerGlobalEvent("MyCoolCustomEvent")
end)
  
  
  