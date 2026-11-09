const Comic = {
    template: `
        <div>
            <div v-if="comic.id">
                <div style="display: flex; flex-wrap: wrap">
                    <div style="width: 33.33%; flex: 33.33% 0 0;">
                        <img :src="'downloadResource/'+comic.thumbLocalPath" style="
                          max-width: 100%;  border-radius: 3px;
                        "/>
                    </div>
                    <div style="width: 66.66%; flex: 66.66% 0 0;">
                        <p>{{comic.title}}</p>
                        <p>{{comic.author}}</p>
                        <p v-html="JSON.parse(comic.categories).join(', ')"></p>
                        <p>{{comic.chineseTeam}}</p>
                        <p v-html="JSON.parse(comic.tags).join(', ')"></p>
                    </div>
                </div>
                <div style="height: 1em"></div>
                <div style="border-top: #66666666 solid 1px;"></div>
                <div style="padding: 1em">
                    <p>{{comic.description}}</p>
                </div>
                <div style="border-top: #66666666 solid 1px"></div>
                <div style="height: 1em"></div>
                <div style="display: flex; flex-wrap: wrap">
                    <div v-for="chapter in chapters" style="padding: .5em">            
                        <router-link :to="'/reader/'+chapter.id" >
                            <button>{{chapter.title}}</button>                        
                        </router-link>
                    </div>
                </div>
            </div>
        </div>
      `,
    setup() {
        const comic = Vue.ref({});
        const chapters = Vue.ref([]);
        Vue.onMounted(() => {
            const id = VueRouter.useRoute().params.id;
            axios.get('/comic/' + id)
                .then(response => {
                    comic.value = response.data;
                })
                .catch(error => {
                    console.log(error);
                });
            axios.get('/comic/chapters/' + id)
                .then(response => {
                    chapters.value = response.data;
                })
                .catch(error => {
                    console.log(error);
                });
        });
        return {
            comic,
            chapters,
        };
    }
}
app.component('Comic', Comic);
