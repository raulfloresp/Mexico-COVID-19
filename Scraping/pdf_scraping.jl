#A partir de PDFs con tablas de la SSA, devuelve un CSV.

#Paquetería para leer pdfs y manipular fechas
using PDFIO
using Dates
using DelimitedFiles

#Devuelve el texto del pdf como un string
function texto_pdf(archivo)

  #Abre el documento.
  documento = pdDocOpen(archivo)
  #Genera objetos que representan las páginas.
  pages = pdDocGetPageRange(documento, 1:pdDocGetPageCount(documento))
  #Creamos un buffer para compilar los datos.
  datos = IOBuffer()

  #Escribimos el texto al buffer.
  #Entre cada página forzamos una línea nueva.
  for page in pages

    pdPageExtractText(datos, page)
    write(datos, " \n ")
  end

  #Cerramos el documento.
  pdDocClose(documento)

  #Devolvemos el texto en un string.
  return String(take!(datos))
end

#Separa el string por líneas y elimina aquellas que no corresponden a casos.
function eliminar_nocasos(string)

  #Separa por línea
  rows = split(string, "\n")
  #Revisa que el inicio de la línea sea de la forma {espacios}Número y descarta la línea si no.
  filter!(row -> occursin(r"^ +\d", row), rows)
  #Transforma los substrings en strings:
  rows = String.(rows)

  return rows
end


function procesa_fecha(string)
  try
    return Dates.format(Date(string, "dd/mm/yyyy"), "yyyy-mm-dd")
  catch e
    return ""
  end
end


function procesa_fila(string, index_fechas)
  out = replace(string, r"^\s+" => "")  # espacios al inicio
  out = replace(out, r"\s+$" => "")  # espacios al final
  out = replace(out, r"QUERETARO" => "QUERÉTARO")
  out = split(out, r"\s{2,}")        # mas de dos espacios define entradas

  for i in index_fechas
    out[i] = procesa_fecha(out[i])  # fechas en formato ISO de ser posible
  end

  return out
end

#Función principal que toma un nombre de archivo y escribe el archivo .csv correspondiente:
function scraping(archivo, sospechosos=false; index_fechas=[5])

  @assert endswith(archivo, ".pdf")

  #Remueve la extensión para nombrar el .csv apropiadamente
  nombre = splitext(basename(archivo))[1]

  #Obtenemos los casos en un array:
  casos = procesa_fila.(eliminar_nocasos(texto_pdf(archivo)), index_fechas)

  #Escribe el archivo
  open(nombre*".csv", "w") do io

    if sospechosos
      write(io, "Número_caso,Estado,Sexo,Edad,Fecha_síntomas,Situación,País_fuente,Fecha_regreso\n")
    else
      write(io, "Número_caso,Estado,Sexo,Edad,Fecha_síntomas,Situación,País_fuente,Fecha_regreso\n")
    end

    writedlm(io, casos, ',')  # esto escribe todas las filas con separadores y \n
  end

  return "Done"
end


if abspath(PROGRAM_FILE) == @__FILE__
  archivo = ARGS[1]

  output = scraping(archivo)
  println(output)
end
