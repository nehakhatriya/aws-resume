
async function get_visitors() {
    try {
        let response = await fetch('https://ivx1w9fbk6.execute-api.us-east-2.amazonaws.com/stage-01/count', {
            method: 'GET',
        });
        let data = await response.json()
        document.getElementById("visitors").innerHTML = data['count'];
        console.log(data);
        return data;
    } catch (err) {
        console.error(err);
    }
}


get_visitors();