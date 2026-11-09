const Bookshelf = {
    template: `
        <div style="
            display: flex;
            flex-wrap: wrap;
        ">
              <div v-for="download in downloads" style="
                  flex-basis: calc(100% / 3);
                  width: calc(100% / 3);
                  flex-grow: 0;
                  flex-shrink: 0;
              ">
                <router-link :to="'/comic/'+download.id" >
                    <div style="width: 95%; margin: 4% 2.5% auto;">
                        <img :src="'downloadResource/'+download.thumbLocalPath" style="
                          max-width: 100%;  border-radius: 3px;
                        "/>
                        <p style="
                          height: 1.4em;
                          line-height: 1.2em;
                          white-space: nowrap;
                          overflow: hidden;
                          text-overflow: ellipsis;
                          -webkit-line-clamp: 2; 
                          ">
                            {{download.title}}
                        </p>
                    </div>
                </router-link>
              </div>
        </div>
      `,
    setup() {
        const downloads = Vue.ref([]);
        Vue.onMounted(() => {
            axios.get('/allDownloads.json')
                .then(response => {
                    downloads.value = response.data;
                })
                .catch(error => {
                    console.log(error);
                });
        });
        return { downloads };
    },
}
app.component('Bookshelf', Bookshelf);
