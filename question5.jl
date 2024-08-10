# Le package Plots va nous permettre de dessiner
# mais il faut auparavant avoir taper: import Pkg; Pkg.add("Plots")

ENV["GKSwstype"] = "nul"  # redirige les sorties de Plots vers les fichiers et non à l'écran
using Plots
using JuMP
using CPLEX
using Random

# Fonction qui lit un fichier de données et renvoie le nombre de données et la liste des données
# Retourne: n: nombre de villes
# Remplit les tableaux
#    tabX, tabY: coordonnées des villes
#    f: poids des villes

function Lit_fichier_UFLP(nom_fichier, tabX, tabY, f)

  n=0
  
  open(nom_fichier) do fic

        for (i,line) in enumerate(eachline(fic)) 
              lg = split(line," ")      # découpe la ligne suivant les espaces et crée un tableau 
              if (i<=1) 
                  n= parse(Int,lg[1])
              end
              if (i>=2) && (i<=n+1) 
                 push!(tabX,parse(Float64,lg[3]))
                 push!(tabY,parse(Float64,lg[4]))	
                 push!(f,parse(Float64,lg[5]))               
              end              
        end    
  end
  return n
end

function Lit_coordonnees_ville(nom_fichier, coordVillesX, coordVillesY)
  
  open(nom_fichier) do fic

        for (i,line) in enumerate(eachline(fic)) 
              lg = split(line," ")      # découpe la ligne suivant les espaces et crée un tableau 
              push!(coordVillesX,parse(Float16,lg[5]))
              push!(coordVillesY,parse(Float16,lg[6]))	
        end    
  end
end

# Fonction Dessine instance
function Dessine_UFLP(nom_fichier)

    n=0
    tabX=Float64[]
    tabY=Float64[]
    f= Float64[]
    
    println("Lecture du fichier: ", nom_fichier)

    n= Lit_fichier_UFLP(nom_fichier, tabX, tabY, f)

    println("Le fichier contient ",n, " villes")
  
    nom_fichier_en_deux_morceaux = split(nom_fichier,".") # découpe le nom du fichie d'entrée sans l'extension
    nom_fichier_avec_pdf_a_la_fin= nom_fichier_en_deux_morceaux[1]*".pdf"

    println("Création du fichier pdf de l'instance: ", nom_fichier_avec_pdf_a_la_fin)

    Plots.plot(tabX,tabY,seriestype = :scatter)
    Plots.savefig(nom_fichier_avec_pdf_a_la_fin)  # Ecrit la courbe créée à la ligne précédente dans un fichier .pdf
end

# Fonction pour calculer la distance euclidienne entre deux points
function dist(x1, y1, x2, y2)
    return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

# Fonction Dessine solution
function Dessine_UFLP(nom_fichier, n, tabX, tabY, S)

    X=Float64[]
    Y=Float64[]	
    
    nom_fichier_en_deux_morceaux = split(nom_fichier,".") # découpe le nom du fichie d'entrée sans l'extension
    nom_fichier_avec_pdf_a_la_fin= nom_fichier_en_deux_morceaux[1]*"_sol.pdf"

    println("Création du fichier pdf de la solution: ", nom_fichier_avec_pdf_a_la_fin)

    Plots.plot(tabX,tabY,seriestype = :scatter, legend = false)
    
    for i=1:n
       min=10e10
       minj=0
       for j=1:n
          if ( (S[j]==1) && (min>dist(tabX[i],tabY[i],tabX[j],tabY[j])) )
              min=dist(tabX[i],tabY[i],tabX[j],tabY[j])                          
              minj=j             
          end
       end
       if (i!=minj)
          empty!(X)
          empty!(Y)			
          push!(X,tabX[i])
          push!(X,tabX[minj])	
          push!(Y,tabY[i])
          push!(Y,tabY[minj])	          
          Plots.plot!(X,Y, legend = false)
       end
    end

    Plots.savefig(nom_fichier_avec_pdf_a_la_fin)  # Ecrit la courbe créée à la ligne précédente dans un fichier .pdf
end

function genere_solution_aleatoire(n, p)
    if p > n
        error("Le nombre de solutions p ne peut pas être supérieur à la taille n.")
    end

    S = zeros(Int, n)  # Crée un vecteur de taille n rempli de 0
    indices = randperm(n)[1:p]  # Génère une permutation aléatoire des indices et en prend les p premiers
    for i in indices
        S[i] = 1
    end

    return S
end

# Fonction qui calcule la distance max entre une ville et une antenne
function distance_maximale(n, tabX, tabY, S)
    distance_max = 0.0

    for i in 1:n
        if S[i] == 0
            min_distance = Inf
            for j in 1:n
                if S[j] == 1
                    distance = dist(tabX[i], tabY[i], tabX[j], tabY[j])
                    if distance < min_distance
                        min_distance = distance
                    end
                end
            end
            if min_distance > distance_max
                distance_max = min_distance
            end
        end
    end

    return distance_max
end

# Création des tableaux nécessaires
tabX = Float64[]
tabY = Float64[]
f = Float64[]

# Appel de la fonction Lit_fichier_UFLP
n = Lit_fichier_UFLP("inst_500.flp", tabX, tabY, f)

# Affichage des résultats
println("Nombre de villes: ", n)
p = 10
S = genere_solution_aleatoire(n, p)
Dessine_UFLP("res", n, tabX, tabY, S)
println("Distance maximale entre une ville et une antenne : ", distance_maximale(n, tabX, tabY, S))