// ------------------------------------------------------------
// SERVICE MANAGER
// ------------------------------------------------------------
// Simple Service Manager for managing multiple WebService
// instances. Includes rudimentary discovery through support
// for WSIL.
// ------------------------------------------------------------
// sneville@macromedia.com
// ------------------------------------------------------------

ServiceManager = function(wsilURI)
{
    this.loadedServices = new Object();

    this.logCollection = new Object(); this.logCollection.data = new Object();
    //SharedObject.getLocal("serviceLogs");
    if (this.logCollection.data.serviceLogs == undefined)
    {
        this.logCollection.data.serviceLogs = new Object();
    }

    //if wsilURI is defined, load it and add all discovered WSDL URIs
    if (wsilURI != undefined)
    {
        this.loadWSIL(wsilURI);
    }
}

var o = ServiceManager.prototype;

o.setLogLevel = function(logLevel)
{
    this.logLevel = logLevel;
}

o.loadWSIL = function(url)
{
    // doesn't actually load services, but makes them available via list operations
    wsilDoc = new XML();
    wsilDoc.ignoreWhite = true;
    wsilDoc.load(url);
    wsilDoc.manager = this;
    wsilDoc.onLoad = function(success)
    {
        if (success)
        {
            var knownServices = new Array();
            var inspectionNode = this.firstChild;
            var serviceNodes = inspectionNode.childNodes;
            var numServices = serviceNodes.length;
            for (var i=0; i<numServices; i++)
            {
                var websvc = new Object();
                var serviceNode = serviceNodes[i];
                var serviceDetails = serviceNode.childNodes;
                var numDetails = serviceDetails.length;
                for (var n=0; n<numDetails; n++)
                {
                    var nd = serviceDetails[n];
                    if (nd.nodeName == "abstract")
                    {
                        websvc.abstract = nd.childNodes[0].toString();
                    }
                    else if (nd.nodeName == "description")
                    {
                        if (nd.attributes.location != undefined)
                        {
                            websvc.location = nd.attributes.location;
                        }
                    }
                }
                knownServices.push(websvc);
            }
            this.manager.onLoadWSIL(knownServices);
        }
    }
}

o.getService = function(wsdlURI)
{
    var s = undefined;

    // if already loaded, get it
    // if not already loaded, create it
    if (this.loadedServices[wsdlURI] != undefined)
    {
        s = this.loadedServices[wsdlURI];
    }

    else
    {
        var newlog = new Log(this.logLevel, "Service Stub");
        newlog.mgr = this;
        newlog.wsdlURI = wsdlURI;

        newlog.onLog = function(txt)
        {
            this.mgr.logLocal(txt, this.wsdlURI);
            this.mgr.log(txt);
        }

        this.logCollection.data.serviceLogs[wsdlURI] = "Web Service Log";

        s = new WebService(wsdlURI, newlog);

        this.loadedServices[wsdlURI] = s;
    }

    return s;
}

o.logLocal = function(txt, wsdlURI)
{
    var persistentLog = this.logCollection.data.serviceLogs[wsdlURI];
    persistentLog += txt + newline;
    this.logCollection.data.serviceLogs[wsdlURI] = persistentLog;
    this.logCollection.flush();
}

o.getServiceLogMessages = function(wsdlURI)
{
    var persistentLog = this.logCollection.data.serviceLogs[wsdlURI];
    return persistentLog;
}

o.removeService = function(wsdlURI)
{
    this.loadedServices[wsdlURI] = undefined;
}

o.getServices = function()
{
    var serviceArray = new Array();
    for (var wsdlURI in this.loadedServices)
    {
        serviceArray.push(this.loadedServices[wsdlURI]);
    }
    return serviceArray;
}

o.getServicePorts = function(serviceName)
{
    var portArray = new Array();
    var s = this.getServices();
    for (var i=0; i<s.length; i++)
    {
        if (s[i] == serviceName)
        {
            var websvc = this.loadedServices[s[i]];
            var availablePorts = websvc.stub.servicePortMappings[serviceName];
            for (var portName in availablePorts)
            {
                portArray.push(portName);
            }
            break;
        }
    }
    return portArray;
}

o.getServiceOperations = function(serviceName)
{
    var opArray = new Array();
    for (var wsdlURI in this.loadedServices)
    {
        var websvc = this.loadedServices[wsdlURI];
        if (websvc._name == serviceName)
        {
            var currPort = websvc.stub.activePort;
            for (var opName in currPort)
            {
                opArray.push(opName);
            }
            break;
        }
    }
    return opArray;
}

o.getServiceSOAPCalls = function(serviceName)
{
    var callArray = new Array();
    for (var wsdlURI in this.loadedServices)
    {
        var websvc = this.loadedServices[wsdlURI];
        if (websvc._name == serviceName)
        {
            var currPort = websvc.stub.activePort;
            for (var opName in currPort)
            {
                callArray.push(currPort[opName]);
            }
            break;
        }
    }
    return callArray;
}
