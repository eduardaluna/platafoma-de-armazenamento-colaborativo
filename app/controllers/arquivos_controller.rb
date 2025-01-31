$LOAD_PATH << '.'
require 'app/services/cesar_cripto.rb'
require "down"


class ArquivosController < ApplicationController
  before_action :set_arquivo, only: %i[ show edit update destroy ]
  before_action :redireciona, only: %i[edit update]

  def redireciona
    redirect_to root_path
  end

  # GET /arquivos or /arquivos.json
  def index
    @arquivos = Arquivo.all
    @meus_arquivos = Arquivo.where(user_id: current_user.id)
  end

  # GET /arquivos/1 or /arquivos/1.json
  def show
  end

  # GET /arquivos/new
  def new
    @arquivo = Arquivo.new
  end

  # GET /arquivos/1/edit
  def edit
  end

  # POST /arquivos or /arquivos.json
  def create
    
    @arquivo = Arquivo.new(arquivo_params)
    @arquivo.user = current_user
    @chave = ""

    @cached_id = JSON.parse(@arquivo.cached_image_data)["id"]

    respond_to do |format|
      if @arquivo.save
        if @arquivo.cripto_tipo == 'No_cypto'
          format.html { redirect_to arquivo_url(@arquivo), notice: "File was successfully created." }
          format.json { render :show, status: :created, location: @arquivo }       
        else   
          arq = abrir_arquivo()

          if @arquivo.cripto_tipo == "Remove Line"          
            linha(arq)
          elsif @arquivo.cripto_tipo == "Caesar"         
            cesar(arq)
          else #Cripto eh AES
            cripto_aes(arq)
          end

          File.delete("public/uploads/cache/#{@cached_id}") if File.exist?("public/uploads/cache/#{@cached_id}")
          File.delete("public/uploads/store/#{@filename3}") if File.exist?("public/uploads/store/#{@filename3}")
          format.html { redirect_to arquivo_url(@arq2), notice: "File was successfully created." }
          format.json { render :show, status: :created, location: @arq2 }      
        end
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @arquivo.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # PATCH/PUT /arquivos/1 or /arquivos/1.json
  def update
    respond_to do |format|
      if @arquivo.update(arquivo_params)
        format.html { redirect_to arquivo_url(@arquivo), notice: "File was successfully updated." }
        format.json { render :show, status: :ok, location: @arquivo }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @arquivo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /arquivos/1 or /arquivos/1.json
  def destroy
    @arquivo.destroy

    respond_to do |format|
      format.html { redirect_to arquivos_url, notice: "File was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def abrir_arquivo()
    info = @arquivo.image_data

    @listaInfo = info.split('"')
    
      @extensao = ""
      lista = @listaInfo[13].split('.')
      lista.each_with_index do |l, index|
        if index > 0
          @extensao += "." + l 
        end
      end
      @filename = lista[0]
    
    
    arq = File.new("public/uploads/store/#{@listaInfo[3]}", "r+")

    arq
  end

  def linha(arquivo)
    cont = 0
    temp_linha = []
    arquivo.each do |a|
      if(cont == 2)
        @chave = a
      else
        temp_linha.append(a)
      end
      cont+=1
    end
    escrever_arquivo(temp_linha, arquivo)
  end

  def cesar(arquivo)
    cesar = Cesar.new('', 13)
    @chave = 13.to_s
    tmp = []         
    arquivo.each do |a|
      cesar.text = a
      novaLinha = cesar.cipher
      tmp << novaLinha
    end
    escrever_arquivo(tmp, arquivo)
  end

  def cripto_aes(arq)
    @chave = AES.key


    tmp = []      
    cont = 0   
    palavra = ""
    arq.each do |a|
      if (cont == 3)
        for b in 0..9 do
          palavra += a[b].to_s       
        end 
        novaLinha = AES.encrypt(palavra, @chave)
        tmp << novaLinha + a[10..(a.length)]
      else
        tmp << a
      end


      cont = cont + 1
    end
    escrever_arquivo(tmp, arq)
  end

  def escrever_arquivo(tmp, arq)
    arq.close unless arq.closed?

    arqTmp = File.new("public/uploads/store/#{@filename+" - Encrypt_"+@arquivo.cripto_tipo+@extensao}", "w")

    tmp.each  do |t|
      arqTmp.write(t.force_encoding("UTF-8"))
    end
    arqTmp.close unless arqTmp.closed?
    arqTmpNew = File.new("public/uploads/store/#{@filename+" - Encrypt_"+@arquivo.cripto_tipo+@extensao}", "r")
    arqTmpNew
    @arq2 = Arquivo.new(image: arqTmpNew, description: @arquivo.description, user_id: current_user.id, cripto_tipo: @arquivo.cripto_tipo, cripto_chave: @chave)
    
    @arq2.save
    @filename3 = JSON.parse(@arq2.image_data)["id"]
    @arquivo.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_arquivo
      @arquivo = Arquivo.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def arquivo_params
      params.require(:arquivo).permit(:image, :description, :user_id, :cripto_tipo, :cripto_chave)
    end

end
